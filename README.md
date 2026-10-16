# 🛡️ بکاپ پنل‌های سنایی (x-ui)

آخرین بکاپ: **20261016_073431** — روی سرور `ubuntu-Frankfurt-1gb`

## ⚡ بازگردانی با یک خط دستور

```bash
GHTOKEN=<توکن_گیت‌هاب_تو> bash -c 'curl -fsSL https://raw.githubusercontent.com/arshiyaazizi/xui-backup/main/install.sh | bash'
```

> 🔑 توکن داخل اسکریپت نیست (گیت‌هاب push حاوی رمز رو رد می‌کنه) —
> از متغیر محیطی `GHTOKEN` میاد. توکن باید دسترسی **Contents: Read** داشته باشه.

### این اسکریپت چیکار میکنه؟
| مرحله | منبع |
|---|---|
| نصب **x-ui** | 🌐 ریپوی رسمی `MHSanaei/3x-ui` — نسخه **۳.۳.۱ پین‌شده** (آپدیت نمیشه) |
| نصب **داکر** | 🌐 `get.docker.com` رسمی |
| نصب **acme.sh** | 🌐 ریپوی رسمی `Neilpang/acme.sh` |
| **دیتابیس + فایل‌ها** | 📦 همین بکاپ |
| **گواهی‌ها** | 📦 همین بکاپ |

## 📦 چی توی بکاپ هست (فقط داده)

| مورد | مسیر |
|---|---|
| دیتابیس + unit پنل لوکال | `/etc/x-ui/x-ui.db` + `x-ui.service` |
| **config.json هسته xray** | `/usr/local/x-ui/bin/config.json` + نسخه داکر |
| دیتابیس + گواهی پنل داکر | `/root/sanaei-second/` |
| **همه‌ی گواهی‌ها** | `/root/cert/` + داده‌ی `/root/.acme.sh/` |

```
created_at=20261016_073431
hostname=ubuntu-Frankfurt-1gb
public_ip=172.86.94.167
local_xui_version=3.3.1
docker_image=ghcr.io/mhsanaei/3x-ui:latest
docker_container=3xui_app
local_panel_port=3399
local_panel_basepath=/iXDXsPtDsiQyj2ftDY/
docker_panel_port=2053
inbounds_local=37050,443,3397,2083,8081,80
inbounds_docker=8142
clients_local=36
clients_docker=40
```

## 🔐 هشدار
ریپو **خصوصی** است (حاوی کلیدهای خصوصی TLS و دیتابیس پنل).
هرگز عمومیش نکن.

## 🕐 بکاپ خودکار
هر روز ساعت **۰۳:۳۰ بامداد تهران** (`/root/xui-backup/backup.sh`).
