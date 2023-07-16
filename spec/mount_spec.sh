mount="./sbin/mount.crypto_LUKS"

Mock mount
  mount_args="$*"
  %preserve mount_args
End

Mock cryptsetup
  crypt_args="$*"
  %preserve crypt_args
End

Describe 'mount'
  It 'forwards arguments to mount'
    When run "$mount" /dev/sda1 /mnt/data -sfnv -N ns -o opt1,opt2 -t type.sub
    The value "$crypt_args" should eq 'luksOpen /dev/sda1 _dev_sda1'
    The value "$mount_args" should eq '-s -f -n -v -N ns -o opt1,opt2 /dev/mapper/_dev_sda1 /mnt/data'
  End
  It 'forwards arguments to cryptsetup'
    When run "$mount" /dev/sda1 /mnt/data -o opt1,cryptsetup=opt3,opt2
    The value "$crypt_args" should eq 'luksOpen /dev/sda1 _dev_sda1 opt3'
    The value "$mount_args" should eq '-o opt1,opt2 /dev/mapper/_dev_sda1 /mnt/data'
  End
  It 'supports options with spaces'
    When run "$mount" /dev /mnt -o 'opt1,long opt,opt2'
    The value "$crypt_args" should eq 'luksOpen /dev _dev'
    The value "$mount_args" should eq '-o opt1,long opt,opt2 /dev/mapper/_dev /mnt'
  End
  It 'supports complex cryptsetup options'
    When run "$mount" /dev /mnt -o 'opt1,cryptsetup=--key-file="/dev/key file" --offset 5,opt2'
    The value "$crypt_args" should eq 'luksOpen /dev _dev --key-file="/dev/key file" --offset 5'
    The value "$mount_args" should eq '-o opt1,opt2 /dev/mapper/_dev /mnt'
  End
  It 'does not allow for comma in cryptsetup options'
    # This testcase is only to document the current behavior and can be improved.
    When run "$mount" /dev /mnt -o 'opt1,cryptsetup=--custom=1,2,3,opt2'
    The value "$crypt_args" should eq 'luksOpen /dev _dev --custom=1'
    The value "$mount_args" should eq '-o opt1,2,3,opt2 /dev/mapper/_dev /mnt'
  End
End
