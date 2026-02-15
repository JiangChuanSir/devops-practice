#!/bin/bash
LOG="/var/log/lnmp_monitor.log"
for svc in nginx mysqld php-fpm; do
    if systemctl is-active $svc >/dev/null 2>&1; then
        echo "$(date '+%F %T') $svc is running" >> $LOG
    else
        echo "$(date '+%F %T') $svc is DOWN, restarting..." >> $LOG
        systemctl restart $svc
        # 可选：钉钉告警
        # curl -X POST -H "Content-Type: application/json" -d '{"msgtype":"text","text":{"content":"'$svc' down on '$(hostname)'"}}' https://oapi.dingtalk.com/robot/send?access_token=xxx
    fi
done
