if [ $(id -u) -ne 0 ]; then
    echo "Please run as root";
    exit 1;
fi

# We don't always need that many watches, but increase these limits in case we have a lot of parallization on a single host
echo 524288 > /proc/sys/fs/inotify/max_user_watches
echo 512 > /proc/sys/fs/inotify/max_user_instances

cat /proc/sys/fs/inotify/max_user_watches
cat /proc/sys/fs/inotify/max_user_instances

echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo >/proc/sys/kernel/core_pattern