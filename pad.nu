let $bit_from_start = "blake"
###

#@ Config
./dev-env config
exit

#@ Karabiner
./dev-env karabiner
exit

#@ say hello
#MISE dir="dots"
print $env.TEST_ENV
print $bit_from_start


print "testing123"

#@ add numbers
1 + 1
