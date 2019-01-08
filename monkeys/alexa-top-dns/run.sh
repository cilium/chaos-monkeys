#!/bin/bash

ERROR_MSG="Error while looking up dns from top alexa sites"

. $(dirname ${BASH_SOURCE})/helpers.bash

init_monkey

[ -z "$SLEEP" ] && {
	SLEEP=10
}

endpoint_debug_enable

names=("google.com" "youtube.com" "facebook.com" "baidu.com" "wikipedia.org" "qq.com" "yahoo.com" "amazon.com" "taobao.com" "reddit.com" "tmall.com" "google.co.in" "twitter.com" "live.com" "sohu.com" "jd.com" "yandex.ru" "google.co.jp" "instagram.com" "weibo.com" "sina.com.cn" "360.cn" "login.tmall.com" "blogspot.com" "google.com.hk" "linkedin.com" "netflix.com" "google.com.br" "yahoo.co.jp" "office.com" "microsoftonline.com" "google.co.uk" "csdn.net" "vk.com" "google.fr" "mail.ru" "google.de" "pages.tmall.com" "aliexpress.com" "twitch.tv" "alipay.com" "microsoft.com" "google.ca" "google.ru" "whatsapp.com" "t.co" "ebay.com" "stackoverflow.com" "amazon.co.jp" "naver.com" "ok.ru" "bing.com" "livejasmin.com" "google.com.mx" "msn.com" "github.com" "google.it" "paypal.com" "tribunnews.com" "google.es" "wordpress.com" "google.co.kr" "googleusercontent.com" "imdb.com" "google.com.tr" "google.com.tw" "apple.com" "tumblr.com" "bilibili.com" "google.com.au" "imgur.com" "amazon.de" "pinterest.com" "amazon.co.uk" "adobe.com" "fbcdn.net" "dropbox.com" "thestartmagazine.com" "google.co.id" "espn.com" "amazon.in" "wikia.com" "detail.tmall.com" "xinhuanet.com" "quora.com" "google.pl" "instructure.com" "zhihu.com" "pixnet.net" "bongacams.com" "hao123.com" "amazonaws.com" "google.co.th" "bbc.com" "google.cn" "tianya.cn" "google.com.ar" "ettoday.net" "exosrv.com")

while :
do
	start_monitor
	start_tcpdump

	for name in ${names[*]}
	do
		error=false
		dig $name
		CODE=$?
		[ "$CODE" -ne "0" ] && {
			dig +tcp $name
			CODE2=$?

			[ "$CODE2" -ne "0" ] && {
				notify_slack ":fire: *$ERROR_MSG: $line* (pod $HOSTNAME, exit code udp $CODE, exit code tcp $CODE2) :face_palm:"
				test_fail
				exit 1
			}
		}
	sleep $(($SLEEP/10))
	done

	stop_monitor
	stop_tcpdump

	sleep $SLEEP
done
