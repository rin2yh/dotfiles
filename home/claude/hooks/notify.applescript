on run
  try
    do shell script "test -n \"${CC_INVOCATION-}\""
  on error
    return
  end try
  try
    set b to do shell script "printf %s \"${CC_BODY-}\""
  on error
    set b to ""
  end try
  try
    set t to do shell script "printf %s \"${CC_TITLE-}\""
    if t is "" then set t to "Claude Code"
  on error
    set t to "Claude Code"
  end try
  display notification b with title t
end run
