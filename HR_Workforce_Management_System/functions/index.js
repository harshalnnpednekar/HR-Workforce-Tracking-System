const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

exports.autoMarkAbsent = onSchedule(
  {
    schedule: '59 23 * * *',
    timeZone: 'Asia/Kolkata',
  },
  async () => {
    const now = new Date();
    const dayKey = formatDayKey(now);
    const dayLabel = formatDayLabel(now);
    const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const dayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
    const absentNames = [];

    let usersSnapshot = await db
      .collection('users')
      .where('role', '==', 'employee')
      .where('isActive', '==', true)
      .get();

    if (usersSnapshot.empty) {
      usersSnapshot = await db
        .collection('users')
        .where('role', '==', 'employee')
        .where('status', '==', 'active')
        .get();
    }

    for (const userDoc of usersSnapshot.docs) {
      const uid = userDoc.id;
      const user = userDoc.data() || {};

      const onLeaveSnapshot = await db
        .collection('leaves')
        .where('uid', '==', uid)
        .where('status', '==', 'approved')
        .where('fromDate', '<=', admin.firestore.Timestamp.fromDate(dayEnd))
        .where('toDate', '>=', admin.firestore.Timestamp.fromDate(dayStart))
        .limit(1)
        .get();

      if (!onLeaveSnapshot.empty) {
        continue;
      }

      const recordRef = db.collection('attendance').doc(uid).collection('records').doc(dayKey);
      const recordSnap = await recordRef.get();
      if (recordSnap.exists) {
        continue;
      }

      await recordRef.set({
        date: dayKey,
        status: 'absent',
        clockIn: null,
        clockOut: null,
        totalHours: 0,
        employeeName: valueOrDefault(user.name, 'Employee'),
        department: valueOrDefault(user.department, ''),
        designation: valueOrDefault(user.designation, ''),
        photoUrl: valueOrDefault(user.photoUrl, ''),
        isManual: false,
        markedBy: 'system:autoMarkAbsent',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      absentNames.push(valueOrDefault(user.name, 'Employee'));
    }

    if (absentNames.length > 0) {
      const adminUids = await getAdminUserIds();
      await Promise.all(
        adminUids.map((adminUid) =>
          addNotification(adminUid, {
            title: `${absentNames.length} Employees Absent Today`,
            message: `${absentNames.length} employees were auto-marked absent`,
            subtitle: `${dayLabel} · ${absentNames.slice(0, 5).join(', ')}`,
            type: 'absent_summary',
            relatedId: dayKey,
            absentCount: absentNames.length,
            absentNames: absentNames.slice(0, 15),
          })
        )
      );
    }
  }
);

exports.payrollReminder = onSchedule(
  {
    schedule: '0 9 * * *',
    timeZone: 'Asia/Kolkata',
  },
  async () => {
    const now = new Date();
    if (now.getDate() < 28) {
      return;
    }

    const monthYear = monthDocId(now);
    const monthLabel = monthLabelFromDocId(monthYear);
    const reminderDate = formatDayKey(now);

    const pendingSnapshot = await db
      .collectionGroup('months')
      .where('monthYear', '==', monthYear)
      .where('status', '==', 'pending')
      .get();

    if (pendingSnapshot.empty) {
      return;
    }

    const adminUids = await getAdminUserIds();
    await Promise.all(
      adminUids.map(async (adminUid) => {
        const exists = await db
          .collection('notifications')
          .doc(adminUid)
          .collection('items')
          .where('type', '==', 'payroll_reminder')
          .where('relatedId', '==', monthYear)
          .where('reminderDate', '==', reminderDate)
          .limit(1)
          .get();
        if (!exists.empty) {
          return;
        }

        await addNotification(adminUid, {
          title: 'Payroll Reminder',
          message: `${pendingSnapshot.size} employees pending payroll`,
          subtitle: monthLabel,
          type: 'payroll_reminder',
          relatedId: monthYear,
          reminderDate,
        });
      })
    );
  }
);

async function getAdminUserIds() {
  let adminSnap = await db
    .collection('users')
    .where('role', '==', 'admin')
    .where('isActive', '==', true)
    .get();

  if (adminSnap.empty) {
    adminSnap = await db.collection('users').where('role', '==', 'admin').get();
  }

  return adminSnap.docs.map((doc) => doc.id).filter((id) => id && id.trim().length > 0);
}

async function addNotification(uid, payload) {
  if (!uid || !uid.trim()) {
    return;
  }

  await db.collection('notifications').doc(uid).collection('items').add({
    ...payload,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function formatDayKey(date) {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function formatDayLabel(date) {
  const month = monthNames[date.getMonth()];
  return `${month} ${date.getDate()}`;
}

function monthDocId(date) {
  const month = monthNames[date.getMonth()].toLowerCase();
  return `${month}-${date.getFullYear()}`;
}

function monthLabelFromDocId(docId) {
  const parts = String(docId).split('-');
  if (parts.length !== 2) {
    return docId;
  }
  const month = parts[0];
  const year = parts[1];
  return `${month.charAt(0).toUpperCase()}${month.slice(1)} ${year}`;
}

const monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

function valueOrDefault(value, fallback) {
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }
  return fallback;
}
