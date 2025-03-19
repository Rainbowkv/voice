local Translations ={
    ["not_on_radio"] = "您没有在任何无线电频道",
    ["joined_to_radio"] = "连接至频道: %{channel}",
    ["restricted_channel_error"] = "您没有权限连接到公职频道!",
    ["invalid_radio"] = "此无线电频率不能使用",
    ["you_on_radio"] = "您已经连接到了此频道",
    ["you_leave"] = "您离开了无线电频道",
    ['volume_radio'] = '新的音量： %{value}',
    ['decrease_radio_volume'] = '已经是最大音量',
    ['increase_radio_volume'] = '已经是最低音量',
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})