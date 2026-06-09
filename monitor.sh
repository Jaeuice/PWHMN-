#!/bin/bash
# 用法: MELON_COOKIES="your_cookies" ./monitor.sh
# 或直接运行（无 cookie 时 API 可能返回空）: ./monitor.sh

COOKIES="${MELON_COOKIES:-}"
NOTIFIED=0

echo "开始监控 P1Harmony 票务... 每秒检测一次"
echo "按 Ctrl+C 停止"
echo "---"

while true; do
  RESPONSE=$(curl -s \
    'https://tkglobal.melon.com/tktapi/glb/product/schedule/gradelist.json?callback=check&v=1&prodId=213323&scheduleNo=100001&sellTypeCodeData=ST0002&langCd=EN&pocCode=SC0002' \
    -H 'referer: https://tkglobal.melon.com/performance/index.htm?langCd=EN&prodId=213323' \
    -H 'x-requested-with: XMLHttpRequest' \
    -H 'user-agent: Mozilla/5.0' \
    ${COOKIES:+-b "$COOKIES"})

  AVAIL=$(python3 -c "
import json, re, sys
text = sys.stdin.read()
match = re.search(r'\((.+)\)', text, re.DOTALL)
data = json.loads(match.group(1)) if match else {}
grades = (data.get('data') or {}).get('seatGradelist') or []
avail = next((int(g.get('realSeatCntlk') or 0) for g in grades if g.get('seatGradeNo') == '12568'), 0)
print(avail)
" <<< "$RESPONSE" 2>/dev/null || echo 0)

  echo -ne "\r$(date '+%H:%M:%S') | 余票: ${AVAIL} 席    "

  if [ "$AVAIL" -gt "0" ]; then
    echo ""
    echo ">>> 有票了！PANDEMONIUM ZONE ${AVAIL} 席！<<<"

    # macOS 系统通知
    osascript -e "display notification \"PANDEMONIUM ZONE ${AVAIL}席！快去抢！\" with title \"🎵 P1Harmony 有票了！\" sound name \"Glass\""

    # 终端响铃
    tput bel

    if [ "$NOTIFIED" -eq "0" ]; then
      curl -s "https://api.day.app/xp8mRq9RmhmofqpwASN6qU/P1Harmony有票了/PANDEMONIUM%20ZONE%20${AVAIL}席！快去抢P2%2FP6！?sound=alarm&isArchive=1" > /dev/null
      NOTIFIED=1
    fi
  fi

  sleep 1
done
