module utils;

import std.datetime : Clock, SysTime, DateTime;

public size_t currTime()
{
    SysTime s = Clock.currTime();
    return s.toUnixTime();
}

public DateTime fromUnix(size_t s)
{
    return cast(DateTime)SysTime.fromUnixTime(s);
}