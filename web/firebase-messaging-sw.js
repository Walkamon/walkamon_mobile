// Import các thư viện Firebase dành cho Web
importScripts(
  "https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js",
);

// Khởi tạo Firebase trong file chạy ngầm
firebase.initializeApp({
  apiKey: "AIzaSyAgKFB69wu2nQOfgROIxeAU2rpRrxXTMRE",
  authDomain: "walkamon-ec4cb.firebaseapp.com",
  projectId: "walkamon-ec4cb",
  storageBucket: "walkamon-ec4cb.firebasestorage.app",
  messagingSenderId: "119004588752",
  appId: "1:119004588752:web:da13394f58825b1bacccd5",
  measurementId: "G-ZLS2JRK0VN",
});

// Thiết lập nhận thông báo
const messaging = firebase.messaging();

// (Tùy chọn) Xử lý khi nhận thông báo ngầm
messaging.onBackgroundMessage(function (payload) {
  console.log("[firebase-messaging-sw.js] Nhận được thông báo ngầm ", payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png", // Icon mặc định của Flutter web
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
