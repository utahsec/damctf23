# solution without quotes

# get the base Object class
object = itself.class
# get all constants, incl class names; first of those is :ARGF
sym = object.constants.sort.first
# turn that symbol into corresponding class
argf = object.const_get sym
# we've redefined system to print a "haha no" message
# it includes the word "flag", split and extract it
flagstr = system.split.sort.first
# ARGF.file is the underlying File object for the ARGument File(s)
# use that to call static File.read
flag = argf.file.class.read flagstr
puts flag

# smallimized
object = itself.class
argf = object.const_get object.constants.sort.first
flag = argf.file.class.read system.split.sort.first
p flag

# minimized
o=itself.class;a=o.const_get o.constants.sort.first;f=a.file.class.read system.split.sort.first;p f
# 99 chars!
