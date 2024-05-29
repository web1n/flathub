#!/bin/bash


gdbus call --session \
  --dest org.kde.StatusNotifierWatcher \
  --object-path /StatusNotifierWatcher \
  --method org.freedesktop.DBus.Introspectable.Introspect > /dev/null 2>&1
if [ $? -ne 0 ]; then
  zenity --error --text "You need install libappindicator to run this application" --icon-name com.dingtalk.DingTalk
  exit 1
fi

get_dingtalk_notifier_item() {
  local notifier_items=$(
    gdbus call --session \
      --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus \
      --method org.freedesktop.DBus.ListNames |
      grep -oE 'org.kde.StatusNotifierItem-[0-9]{1,}-[0-9]'
  )

  local notifier_item
  for notifier_item in $notifier_items; do
    local notifier_id=$(
      gdbus call --session \
        --dest="${notifier_item/\// \/}" --object-path /StatusNotifierItem \
        --method org.freedesktop.DBus.Properties.Get org.kde.StatusNotifierItem Id
    )

    if [[ $notifier_id =~ "com.alibabainc.dingtalk" ]]; then
      echo "${notifier_item/\// \/}"
    fi
  done
}

try_open_dingtalk_window() {
  local notifier_item=$(get_dingtalk_notifier_item)

  if [ -n "$notifier_item" ]; then
    gdbus call --session \
      --dest="$notifier_item" --object-path /MenuBar \
      --method com.canonical.dbusmenu.Event 5 clicked '<"">' 0 >/dev/null
  fi
}

setup_ime() {
  if [[ "$XMODIFIERS" =~ "fcitx" ]]; then
    [ -z "$QT_IM_MODULE" ] && export QT_IM_MODULE=fcitx
    [ -z "$GTK_IM_MODULE" ] && export GTK_IM_MODULE=fcitx
  elif [[ "$XMODIFIERS" =~ "ibus" ]]; then
    [ -z "$QT_IM_MODULE" ] && export QT_IM_MODULE=ibus
    [ -z "$GTK_IM_MODULE" ] && export GTK_IM_MODULE=ibus
  fi
}


try_open_dingtalk_window
setup_ime


cd /app/extra/dingtalk
export LD_PRELOAD="/app/extra/dingtalk/plugins/dtwebview/libcef.so"
exec /app/extra/dingtalk/com.alibabainc.dingtalk "$@"
