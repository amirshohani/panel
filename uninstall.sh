#!/bin/bash
[ "$(id -u)" = "0" ] || { echo "با root اجرا کنید"; exit 1; }
echo "این‌ها حذف می‌شن: پنل (/opt/mypanel)، Xray، sing-box، Caddy، گواهی‌ها (/etc/mypanel)، سرویس‌ها و کرون‌ها."
echo "بکاپ‌ها توی /root/backups می‌مونن."
read -p "برای ادامه بنویسید yes: " A
[ "$A" = "yes" ] || { echo "لغو شد"; exit 1; }
read -p "فایروال (ufw) هم ریست بشه؟ فقط پورت SSH باز می‌مونه [y/N]: " FW

mkdir -p /root/backups/tools && chmod 700 /root/backups
for f in pack.sh publish.sh install.template.sh uninstall.sh; do
  [ -f /opt/mypanel/$f ] && cp -f /opt/mypanel/$f /root/backups/tools/
done

wg-quick down wg0 >/dev/null 2>&1
systemctl disable --now mypanel xray sing-box caddy >/dev/null 2>&1
systemctl disable --now wg-quick@wg0 >/dev/null 2>&1

rm -f /etc/systemd/system/mypanel.service /etc/systemd/system/xray.service /etc/systemd/system/xray@.service
rm -rf /etc/systemd/system/xray.service.d /etc/systemd/system/xray@.service.d
rm -f /usr/local/bin/xray /usr/local/bin/panel-backup.sh
rm -rf /usr/local/share/xray /usr/local/etc/xray /var/log/xray

apt-get purge -y sing-box caddy >/dev/null 2>&1
rm -f /etc/apt/sources.list.d/caddy-stable.list /usr/share/keyrings/caddy-stable-archive-keyring.gpg
rm -f /etc/apt/sources.list.d/sagernet.* /etc/apt/keyrings/sagernet.* /usr/share/keyrings/sagernet.*
apt-get autoremove -y >/dev/null 2>&1

rm -rf /opt/mypanel /etc/mypanel /etc/caddy /var/lib/caddy /etc/sing-box /var/lib/sing-box /etc/wireguard
rm -rf /var/lib/mypanel-le /var/log/mypanel-le
rm -f /etc/cron.d/panel-backup /etc/cron.d/panel-backup-tg /etc/cron.d/mypanel-cert /etc/cron.d/mypanel-le
rm -f /var/log/certsync.log /run/mypanel-caddy-was-on /tmp/mypanel-boot.sh /tmp/Caddyfile.new

if [ "$FW" = "y" ] || [ "$FW" = "Y" ]; then
  P1=$(echo "$SSH_CONNECTION" | awk '{print $4}')
  P2=$(sshd -T 2>/dev/null | awk '/^port /{print $2}' | head -1)
  PORTS=$(printf '%s\n%s\n' "$P1" "$P2" | grep -E '^[0-9]+$' | sort -u)
  [ -n "$PORTS" ] || PORTS=22
  ufw --force reset >/dev/null 2>&1
  for P in $PORTS; do ufw allow "$P/tcp" >/dev/null 2>&1; done
  ufw --force enable >/dev/null 2>&1
  echo "فایروال ریست شد. پورت(های) باز: $(echo $PORTS | tr '\n' ' ')"
fi

systemctl daemon-reload
systemctl reset-failed >/dev/null 2>&1
echo "پاک شد. بکاپ‌ها: /root/backups  |  ابزارهای ساخت: /root/backups/tools"
