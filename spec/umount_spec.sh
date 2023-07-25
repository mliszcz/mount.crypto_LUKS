# shellcheck shell=sh
umount="./sbin/umount.crypto_LUKS"

Mock umount
  umount_args="$*"
  %preserve umount_args
End

Mock cryptsetup
  crypt_args="$*"
  %preserve crypt_args
End

Mock findmnt
  findmnt_args="$*"
  %preserve findmnt_args
  echo "mapper"
End

Describe 'umount'
  It 'forwards arguments to umount'
    When run "$umount" /etc -flnrv -N ns  -t type.sub
    The value "$findmnt_args" should eq '-n -o SOURCE /etc'
    The value "$crypt_args" should eq 'close mapper'
    The value "$umount_args" should eq "-i -f -l -n -r -v -N ns /etc"
  End
End

