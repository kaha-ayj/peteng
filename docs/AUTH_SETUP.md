# Setup Signup, Verifikasi Email, dan Login Google

Fitur ini memakai backend Go yang sudah ada (`C:\project\peteng-backend`) dan
PostgreSQL Supabase sebagai database. Supabase Auth (GoTrue) **tidak** dipakai;
backend tetap menerbitkan JWT sendiri.

## 1. Migrasi database Supabase

Backend akan mencoba menambahkan kolom otomatis saat startup. Kalau role
database tidak punya izin DDL, jalankan SQL ini sekali di **Supabase → SQL Editor**:

```sql
ALTER TABLE public.warga
  ADD COLUMN IF NOT EXISTS email_verified boolean NOT NULL DEFAULT true;

ALTER TABLE public.warga
  ALTER COLUMN email_verified SET DEFAULT false;

ALTER TABLE public.warga
  ADD COLUMN IF NOT EXISTS google_id text;

ALTER TABLE public.warga
  ADD COLUMN IF NOT EXISTS auth_provider text NOT NULL DEFAULT 'local';

ALTER TABLE public.warga
  ADD COLUMN IF NOT EXISTS verification_token text;

ALTER TABLE public.warga
  ADD COLUMN IF NOT EXISTS verification_expires_at timestamptz;

ALTER TABLE public.warga
  ADD COLUMN IF NOT EXISTS verification_attempts integer NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS warga_google_id_unique
  ON public.warga (google_id)
  WHERE google_id IS NOT NULL;
```

Catatan: user lama otomatis `email_verified = true` agar tidak terkunci.
Akun baru dibuat dengan `email_verified = false` sampai kodenya diverifikasi.

## 2. Konfigurasi backend `.env`

Tambahkan variabel berikut ke `C:\project\peteng-backend\.env`:

```env
APP_ENV=development

# SMTP Gmail
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=alamatkamu@gmail.com
SMTP_PASSWORD=app-password-16-karakter
SMTP_FROM=alamatkamu@gmail.com
SMTP_FROM_NAME=PETENG

APP_NAME=PETENG
APP_VERIFY_URL=http://10.0.172.83:8080/api/warga/verify-email

# Web Client ID dari Google Cloud Console
GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
```

`APP_VERIFY_URL` harus memakai IP LAN laptop (bukan `127.0.0.1`) supaya link
di email bisa dibuka dari HP.

### Gmail App Password

1. Aktifkan **2-Step Verification** di akun Google.
2. Buka <https://myaccount.google.com/apppasswords>.
3. Buat app password baru (nama bebas, mis. `PETENG`).
4. Copy 16 karakter ke `SMTP_PASSWORD`.

Kalau `SMTP_HOST` kosong, backend berjalan dalam **mode dev**: kode verifikasi
muncul di log backend dan di halaman verifikasi aplikasi. Cocok untuk testing
tanpa email asli.

Saat deploy ke production, set `APP_ENV=production` supaya kode verifikasi
**tidak** ikut dikirim di response API.

## 3. Google Cloud Console

1. Buka <https://console.cloud.google.com> dan buat project.
2. **APIs & Services → OAuth consent screen**
   - User type: **External**
   - Isi app name `PETENG`, email support, email developer.
   - Scopes: `openid`, `email`, `profile`.
   - Selama status masih **Testing**, tambahkan email Google kamu sebagai
     **Test user**.
3. **APIs & Services → Credentials → Create Credentials → OAuth client ID**

### Android client

- Application type: **Android**
- Package name: `com.example.peteng`
- SHA-1 debug:

```powershell
cd C:\project\peteng\android
.\gradlew signingReport
```

Ambil nilai `SHA1` pada variant **debug**. Atau:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey -storepass android -keypass android
```

### Web client

- Application type: **Web application**
- Copy **Client ID** (bukan client secret).

Web Client ID ini dipakai di dua tempat:

- Backend: `GOOGLE_CLIENT_ID`
- Flutter: `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`

## 4. Menjalankan aplikasi

```powershell
cd C:\project\peteng

flutter run `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com `
  --dart-define=API_BASE_URL=http://10.0.172.83:8080/api
```

Kalau IP laptop berubah, cukup ganti dua nilai di atas. Jangan lupa
`APP_VERIFY_URL` di `.env` backend.

## 5. Alur yang diuji

1. **Signup** → akun masuk ke tabel `warga` Supabase dengan
   `email_verified = false`.
2. Email berisi **kode 6 digit** dan tombol link verifikasi.
3. Buka halaman verifikasi di aplikasi → masukkan kode → `email_verified = true`.
4. **Login** dengan email + password → dapat JWT.
5. Login sebelum verifikasi → aplikasi otomatis membuka halaman verifikasi.
6. **Login Google** → backend memverifikasi ID token ke Google, membuat/menautkan
   akun di tabel `warga`, lalu menerbitkan JWT.

## 6. Endpoint backend

| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `/api/warga/register` | Buat akun + kirim OTP |
| POST | `/api/warga/verify-email` | `{ "email": "...", "code": "123456" }` |
| POST | `/api/warga/resend-verification` | `{ "email": "..." }` |
| POST | `/api/warga/google` | `{ "id_token": "..." }` |
| GET | `/api/warga/verify-email?email=&code=` | Link verifikasi dari email |
| POST | `/api/warga/login` | Login email + password |

## 7. Troubleshooting

- **`GOOGLE_SERVER_CLIENT_ID belum diisi`** → jalankan dengan `--dart-define`.
- **Google Sign-In langsung gagal di emulator** → emulator harus punya Google
  Play Services. Pakai emulator Play Store atau HP fisik.
- **`PlatformException: 10` / DEVELOPER_ERROR** → SHA-1 belum didaftarkan atau
  package name tidak sama (`com.example.peteng`).
- **Email tidak masuk** → cek folder spam, pastikan App Password benar, dan
  `SMTP_FROM` sama dengan `SMTP_USERNAME`.
- **Link email tidak bisa dibuka dari HP** → `APP_VERIFY_URL` masih `127.0.0.1`
  atau HP tidak satu jaringan dengan laptop.
- **Login bilang email belum diverifikasi** → selesaikan verifikasi atau kirim
  ulang kode dari halaman verifikasi.
