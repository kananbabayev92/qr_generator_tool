# Privacy Policy for Ontero QR

**Last updated:** September 2026

This Privacy Policy applies to the **Ontero QR** mobile application (the "Application") for Android devices, developed and published by **Ontero**. This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our Application and the choices you have associated with that data.

---

### 1. Zero Personal Data Collection (Zero-Knowledge Architecture)
We strongly believe in fundamental digital privacy:
- **Ontero QR does NOT collect, transmit, sell, or rent any personally identifiable information** (such as names, phone numbers, email addresses, precise geolocation, device contacts, or photos) to external servers or third parties.
- All QR code decoding and QR code generation happen **100% locally on your device hardware**.

---

### 2. Device Permissions and How They Are Used
To provide core functionality, the Application requests only the minimal necessary permissions:

- **Camera (`android.permission.CAMERA`):**
  Required strictly for real-time scanning of QR codes and barcodes using your device camera.
  - The video feed is analyzed **in-memory** by the camera scanner engine on your device.
  - The Application does **NOT** record, capture, store, or transmit camera images or video frames to any remote server.
  - Camera hardware features are marked optional (`required="false"`) so all compatible devices can install the app.

- **Photo Library / Gallery Access:**
  Used exclusively when you deliberately choose to pick an image from your device gallery to scan a QR code, or when you choose to export and share a generated QR code image via standard system share dialogs. We do not inspect, collect, or upload any other photos from your device.

- **Internet Access (`android.permission.INTERNET`):**
  Used solely when you tap on web links (URLs) decoded from QR codes to open them in your default external browser, or for optional diagnostic and non-personal ad performance network requests.

---

### 3. Local Data Storage & User Control
- Your scan history, created QR codes, and application settings (such as appearance theme and language preference) are stored **strictly on your physical device** (using encrypted/private SharedPreferences).
- This data never leaves your device and can be permanently deleted at any time:
  1. Directly in the app: Go to **Settings > Storage & Data > Clear**.
  2. In your device system settings: Clear App Data or uninstall the Application.

---

### 4. Children's Privacy
Our Application is intended for a general audience and is not directed to children under the age of 13. We do not knowingly collect personal identifiable information from children under 13.

---

### 5. Security & Built-in Protection
Ontero QR includes built-in security auditing to safeguard users from malicious links, executable downloads (`.apk`, `.exe`, etc.), and unsafe URL scripts. Because your data is processed locally without external server transmission, your private information remains entirely in your control.

---

### 6. Changes to This Privacy Policy
We may update our Privacy Policy periodically. Any updates will be posted directly to this page with a revised "Last updated" date.

---

### 7. Contact Us
If you have any questions, concerns, or suggestions regarding this Privacy Policy, please feel free to reach out to us:
- **Developer / Publisher:** Ontero
- **Support Email:** support@ontero.com
- **Website:** https://github.com/kananbabayev92/qr_generator_tool
