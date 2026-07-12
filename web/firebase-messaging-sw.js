// Import các thư viện Firebase dành cho Web
importScripts(
  "https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js",
);

// Khởi tạo Firebase trong file chạy ngầm
firebase.initializeApp({
  apiKey: "AIzaSyBpWnU-W9RpetKUBnMMT1q3iHgr1bm-ons",
  authDomain: "walkamon-25d80.firebaseapp.com",
  projectId: "walkamon-25d80",
  storageBucket: "walkamon-25d80.firebasestorage.app",
  messagingSenderId: "180347659752",
  appId: "1:180347659752:web:2c656d329a1fd1a48ff05d",
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
