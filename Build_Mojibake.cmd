@echo	off

echo	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo	Mojibake I386 version
echo	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
call	Build_Mojibake_I386.cmd

echo	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo	Mojibake AMD64 version
echo	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
call	Build_Mojibake_AMD64.cmd

pause