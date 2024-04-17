# openEuler安全配置基线 v1.0

|版本|修订说明|修订时间|访问链接|
| ------------ | ------------ | ------------ | ------------ |
|1.0|初始修订|2023年12月|本文档|



## 1 初始部署
## 1.1 文件系统
### 1.1.1 禁止存在无属主或属组的文件或目录

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

系统中不允许存在没有属主或属组的文件或目录，这些文件或目录一般都是由于原属主账号被删除，而文件未被删除导致。

这些文件存在安全隐患，可能导致信息泄露，占用不必要的磁盘空间和系统资源，还可能影响正常业务运行。

需要注意，在容器场景中，容器和宿主机使用不同的user namespace，这导致容器中的文件在宿主机中可能为无属主或属组的目录和文件。
对于容器的rootfs，宿主机已有相应的保护措施：宿主机上的rootfs的父目录，已做了权限控制，仅root用户可以访问。对于此情况的目录和文件可例外。

**规则影响：**

无

**检查方法：**

通过如下两个命令，在系统根目录下查找无属主或属组的目录和文件，如果这两个命令没有返回值，表示系统中不存在无属主或属组的目录和文件：

```bash
# find `df -l | sed -n '2,$p' | awk '{print $6}' ` -xdev -nouser 2>/dev/null
# find `df -l | sed -n '2,$p' | awk '{print $6}' ` -xdev -nogroup 2>/dev/null
```

**修复方法：**

通过rm命令删除无属主或属组的文件，此处需要注意，删除前务必确认确实为无用的文件或目录，否则可使用chown命令将目录或文件修改为正确的、且实际存在的属主或属组，方法如下：

```bash
# rm test -rf
或
# chown test1:test1 test
```

### 1.1.2 禁止存在空链接文件

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

空链接文件一方面属于冗余文件，浪费系统资源，另一方面如果后续在链接目标位置安装或者创建了同名同路径的文件，但却没有清理历史上的链接文件，该目标文件就可以通过链接进行访问，可能导致文件信息泄露甚至被篡改。链接文件所指向的实际文件如果已经被删除，那么链接文件本身也就失去了存在的必要，务必同时删除，确保系统中不存在空链接文件。

需要注意，系统运行时，部分目录下存在一些系统临时文件或链接，这些是随进程动态变化的，可以作为例外忽略，这些目录常见的有：/proc、/run、/var、/sys、/dev。

**规则影响：**

无

**检查方法：**

使用find命令在全局或某个目录下查找空链接文件，例如：

```bash
# find ./ -type l -follow
./testlink
```

该命令如果返回输出为空，表示在指定目录下没有找到空链接文件，否则会返回空链接文件名，如上面例子中的testlink文件。

如果要排除某些目录不做搜索，例如排除/proc、/run、/var、/sys、/dev目录，可使用如下命令，可以搜索到/root目录下testlink是空链接文件，而部分系统目录被排除在外，未被搜索：

```bash
# find / -path /var -prune -o -path /run -prune -o -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -type l -follow
/dev
/proc
/root/testlink
/run
/var
/sys
```

也可以使用-xdev参数，只搜索指定目录所在分区的文件系统，对于其他通过mount挂载的目录不做搜索：

```bash
# find / -xdev -type l -follow
```

**修复方法：**

搜索到空链接文件后，使用rm命令删除该文件：

```bash
# find ./ -type l -follow
./testlink
# rm ./testlink
```
### 1.1.3 禁止存在隐藏的可执行文件

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

在linux系统中，以“.”为前缀的文件是隐藏文件（除了当前目录和上层目录的“.”、“..”），系统中不允许存在可执行的隐藏文件。

.bashrc、.bash_profile、.bash_logout这三个文件是系统在创建用户账号后，账号登录/登出shell时的脚本文件，符合业界惯例，可不删除，其他隐藏的可执行文件必须删除，或去除可执行权限。

**规则影响：**

无

**检查方法：**

通过find命令可以查找是否存在可执行的隐藏文件，如下命令是在根文件系统下全局查找，如果返回为空，则表示未找到任何可执行的隐藏文件，否则列出相应文件：

```bash
# find / -type f -name "\.*" -perm /+x
/etc/skel/.bashrc
/etc/skel/.bash_profile
/etc/skel/.bash_logout
```

**修复方法：**

根据实际情况，有三种修改方式：

- 使用rm命令删除隐藏的可执行文件

  ```bash
  # rm .testfile
  ```

- 使用mv命令将隐藏文件修改为普通文件

  ```bash
  # mv .testfile testfile
  ```

- 使用chmod命令去除可执行权限，例如：

  ```bash
  # chmod 644 .testfile
  ```
### 1.1.4 确保全局可写目录已设置sticky位

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

sticky位，又叫粘滞位，普通文件的粘滞位会被内核忽略。粘滞位被设置在目录的执行许可位置上，用t表示，设置了该位后，其它用户就不可以删除该目录下不属于他的文件和目录。但是子目录不继承该权限，要再设置才可使用。对于全局可写的目录，要求必须设置粘滞位。

如果用户对目录有写权限，则可以删除其中的文件和子目录，即使该用户不是这些文件的所有者，而且也没有读或写许可。

**规则影响：**

无

**检查方法：**

使用如下命令查找指定目录下有全局可写权限且未设置粘滞位的目录，返回为空表示未找到，举例中test目录为全局可写目录，但未设置粘滞位：

```bash
# find ./ -type d -perm -0002 -a ! -perm -1000
./test
```

**修复方法：**

使用chmod命令设置目录粘滞位，其中第一位“1”表示设置粘滞位，设置完成以后，可以通过ll命令查看是否已经设置成功，如下例子中，other用户的x位已经被设置为t：

```bash
# chmod 1777 test
# ll -d test
drwxrwxrwt. 2 root root 4096 Nov  4 14:31 test
```

### 1.1.5 确保UMASK配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

UMASK是默认文件或目录权限的掩码，创建文件或目录的时候，以777权限按位减去UMASK的值，如果是文件，则还需要去掉可执行权限，然后得到文件或目录的默认权限设置。UMASK如果设置不合理，可能导致新建文件权限过小或过大，从而影响业务正常运行或导致安全风险。

考虑到社区版本在不同场景下的易用性，openEuler发行版默认不配置UMASK，请根据实际场景按需配置。

**规则影响：**

按规范要求将UMASK配置为077后，创建的文件默认权限为600，目录默认权限为700，会使属组及其他用户使用受限，降低易用性。

**检查方法：**

- 检查配置文件中UMASK值是否正确，可以添加多个目录同时检查，例如下面代码中同时检查了/etc/bashrc和用户home目录下.bashrc文件，获得umask值为077：

  ```bash
  # grep -i "^umask" /etc/bashrc ~/.bashrc
  /etc/bashrc:umask 0077
  /root/.bashrc:umask 077
  ```

- 使用root用户登录，创建文件或目录，确认权限是否正确：

  ```bash
  # touch test
  # ll test
  -rw-------. 1 root root 0 Nov  4 17:36 test
  
  # mkdir testdir
  # ll -d testdir
  drwx------. 2 root root 4096 Nov  4 17:36 testdir
  ```

- 使用普通账号test登录，创建文件或目录，确认权限是否正确：

  ```bash
  $ touch test
  $ ll test
  -rw-------. 1 test test 0 Nov  4 17:37 test
  
  $ mkdir testdir
  $ ll -d testdir
  drwx------. 2 test test 4096 Nov  4 17:37 testdir
  ```

**修复方法：**

可以在两个地方进行修改：

- 在/etc/bashrc文件中对umask字段进行修改，该文件变化对全局所有用户下次登录有影响：

  ```bash
  # vim /etc/bashrc
  umask 0077
  ```

- 在~/.bashrc文件中对umask字段进行修改或添加，该文件变化只对当前用户下次登录时有影响，如果该文件中的配置同/etc/bashrc不一致，则以该文件为准：

  ```bash
  $ vim /home/test/.bashrc
  umask 0077
  ```
### 1.1.6 禁止存在全局可写的文件

**级别：** 要求

**适用版本：** 全部

**规则说明：** 
全局可写意味着所有用户都可以对文件进行写操作，通常情况下这种权限并不是必须的。如果文件被不合理的设置了全局可写权限，容易被攻击者篡改，导致安全风险。所以如果文件不得不存在全局可写的权限，需要针对实际场景分析安全风险，确保攻击者无法利用此文件进行攻击。

可以在根目录下搜索全局可写文件，需要例外的是：“/sys”、“/proc”这两个系统目录在linux运行时存在大量的全局可写文件，所以在检查时应排除这两个目录，避免混淆。

**规则影响：**

无

**检查方法：**

使用如下命令在根目录下进行搜索（已排除了“/sys”、“/proc”这两个目录），返回全局可写文件列表，如果返回为空，表示无全局可写文件：

```bash
# find / -path /proc -prune -o -path /sys -prune -o -type f -perm -0002 -exec ls -lg {} \;
-rwxrwxrwx. 1 root 0 Dec  1 17:34 /root/test
```

也可以使用-xdev参数，只搜索指定目录所在分区的文件系统，对于其他通过mount挂载的目录不做搜索：

```bash
# find / -xdev -type f -perm -0002 -exec ls -lg {} \;
-rwxrwxrwx. 1 root 0 Dec  1 17:34 /root/test
```

**修复方法：**

对于不合理的权限，使用chmod命令进行修改，去除全局可写，例如：

```bash
# chmod 755 test
# ll test
-rwxr-xr-x. 1 root root 0 Dec  1 17:34 test
```
### 1.1.7 确保移除不需要的文件系统挂载支持

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

Linux系统支持多种文件系统，通过ko方式加载进内核。openEuler作为通用操作系统平台，会提供各种文件系统ko，保存在/lib/modules/(kernel version)/kernel/fs/目录下，可以通过insmod/modprobe命令进行加载支持。禁用不需要的文件系统的挂载支持，可以缩小攻击面，防止攻击者通过利用某些不常用文件系统的漏洞对系统进行攻击。

使用者应根据实际场景，确定哪些文件系统是不需要被支持的，并通过配置禁止这些文件系统被挂载，这些文件系统通常包括：

cramfs、freevxfs、jffs2、hfs、hfsplus、squashfs、udf、vfat、fat、msdos、nfs、ceph、fuse、overlay、xfs

**规则影响：**

移除的文件系统，不再被支持。

**检查方法：**

使用如下命令检查输出结果（例如cramfs，其他文件系统类似），如果输出“install /bin/true”，表示该文件系统已经被禁止挂载，如果输出“insmod /lib/modules/(kernel version)/kernel/fs/cramfs/cramfs.ko”，表示该文件系统未被禁止挂载，并列出ko所在目录：

```bash
# modprobe -n -v cramfs | grep -E '(cramfs|install)'
install /bin/true
```

如果上述命令没有回显，再执行以下命令，如果有输出则表示该文件系统已被挂载：

```bash
# lsmod | grep cramfs
cramfs  135168  0
```

**修复方法：**

对已挂载的文件系统，确定是实际场景不需要被支持的，可通过如下命令移除（例如cramfs，其他文件系统类似）：
```bash
# modprobe -r cramfs
```

在/etc/modprobe.d/目录下，添加一个任意文件名的，并以.conf为后缀的配置文件，属主和属组均为root, 权限600，并根据实际场景将需要被禁止挂载的文件系统按照如下格式填入：

```bash
# vim /etc/modprobe.d/test.conf
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
install vfat /bin/true
install fat /bin/true
install msdos /bin/true
install nfs /bin/true
install ceph /bin/true
install fuse /bin/true
install overlay /bin/true
install xfs /bin/true
```
### 1.1.8 确保无需修改的分区以只读方式挂载

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

以只读方式挂载无需数据修改的文件系统，可以避免无意或恶意的数据篡改行为，减小攻击面。

**规则影响：**

文件系统一旦以只读方式挂载，将无法对文件和目录进行创建、修改、删除动作，用户需要根据实际场景进行配置，操作系统运行必须的文件挂载可以忽略此项要求。

**检查方法：**

通过mount命令查看挂载的文件系统是否符合要求，例如查看/root/readonly目录是否为只读挂载，可以使用如下命令，如果无返回数据，说明该目录未被挂载，或非只读挂载：

```bash
# mount | grep "\/root\/readonly" | grep "\<ro\>"
/dev/vda on /root/readonly type ext4 (ro,relatime,seclabel)
```

**修复方法：**

* 卸载对应挂载点，重新以只读方式挂载：

  ```bash
  # umount /root/readonly
  # mount -o ro /dev/vda /root/readonly/
  ```

* 如果硬盘或分区是通过/etc/fstab配置文件进行挂载的，那么通过修改该文件，为指定挂载点添加ro挂载方式，如：

  ```bash
  # vim /etc/fstab
  /dev/vda /root/readonly ext4 ro 0 0
  ```
### 1.1.9 确保无需挂载设备的分区以nodev方式挂载

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

nodev表示不允许挂载设备文件，用于减小攻击面，增加安全性。目录被挂载时，如果设置了nodev选项，那么该目录下所有块设备、字符设备等设备文件将被解析为普通文件，无法按设备文件进行操作。如果挂载时未设置nodev，将导致安全风险，例如攻击者在U盘上创建了一个文件系统，并在其中创建了一个块设备文件（自己的U盘，有相应的权限），而这个块设备实际是指向/dev/sda之类的服务器硬盘或分区的，如果攻击者有机会将U盘插入到服务器上，服务器又加载了这个U盘，那么攻击者可以通过这个块设备文件访问到相应硬盘数据。如果将上述案例中的U盘改为其他硬盘或分区，也存在类似问题，只要该硬盘或分区上存在恶意构造的设备文件，就可以形成攻击。

openEuler系统中默认如下目录被nodev挂载：/sys、/proc、/sys/kernel/security、/dev/shm、/run、/sys/fs/cgroup、/sys/fs/cgroup/systemd、/sys/fs/pstore、/sys/fs/bpf、/sys/fs/cgroup/files、/sys/fs/cgroup/net_cls,net_prio、/sys/fs/cgroup/devices、/sys/fs/cgroup/freezer、/sys/fs/cgroup/cpu,cpuacct、/sys/fs/cgroup/perf_event、/sys/fs/cgroup/pids、/sys/fs/cgroup/hugetlb、/sys/fs/cgroup/memory、/sys/fs/cgroup/blkio、/sys/fs/cgroup/cpuset、/sys/fs/cgroup/rdma、/sys/kernel/config、/sys/kernel/debug、/dev/mqueue、/tmp、/run/user/0

openEuler存在以下目录（部分目录因硬盘分区，部署平台而不同），这些目录默认未被nodev挂载：/dev、/dev/pts、/、/sys/fs/selinux、/proc/sys/fs/binfmt_misc、/dev/hugepages、/boot、/var/lib/nfs/rpc_pipefs、/boot/efi、/home。

实际场景中，根据业务需要，对不需要挂载设备的分区，采用nodev方式挂载。

**规则影响：**

无

**检查方法：**

通过mount命令检查是否存在需要被设置nodev，但却未被设置的挂载点，对返回数据进行分析，确认未设置nodev的挂载点是否正确。此处举例中，除了系统默认未使用nodev挂载的目录外，用户新增的/root/nodev挂载点未使用nodev方式挂载：

```bash
# mount | grep -v "nodev" | awk -F " " '{print $3}'
/dev
/dev/pts
/
/sys/fs/selinux
/proc/sys/fs/binfmt_misc
/dev/hugepages
/boot
/boot/efi
/home
/root/nodev
```

**修复方法：**

* 卸载对应挂载点，重新以nodev方式挂载：
  ```bash
  # umount /root/nodev
  # mount -o nodev /dev/vda /root/nodev/
  ```

* 如果硬盘或分区是通过/etc/fstab配置文件进行挂载的，那么通过修改该文件，为指定挂载点添加nodev挂载方式，如：

  ```bash
  # vim /etc/fstab
  /dev/vda /root/nodev ext4 nodev 0 0
  ```
### 1.1.10 确保无可执行文件的分区以noexec方式挂载

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

数据盘只是用于保存系统运行过程中的数据，并不需要在数据盘上执行相关命令，对于这种情况，该硬盘或分区必须以noexec方式挂载，提高安全性，减少攻击面。

**规则影响：**

硬盘或分区如果以noexec方式挂载，那么该挂载点目录下的可执行文件无法直接运行。

**检查方法：**

通过mount命令查看指定挂载点目录是否以noexec方式挂载：

```bash
# mount | grep "\/root\/noexec" | grep "noexec"
/dev/vda on /root/noexec type ext4 (rw,noexec,relatime,seclabel)
```

**修复方法：**
* 卸载对应挂载点，重新以noexec方式挂载：
  ```bash
  # umount /root/noexec
  # mount -o noexec /dev/vda /root/noexec/
  ```

* 如果硬盘或分区是通过/etc/fstab配置文件进行挂载的，那么通过修改该文件，为指定挂载点添加noexec挂载方式，如：

  ```bash
  # vim /etc/fstab
  /dev/vda /root/noexec ext4 noexec 0 0
  ```
### 1.1.11 确保可移动设备分区以noexec、nodev方式挂载

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

可移动设备本身存在不确定性，来源、过往使用情况、运输过程等都无法保证绝对安全，因此可移动设备往往是病毒传播的主要宿主设备。所以针对可移动设备，要求必须以noexec、nodev方式挂载，提高安全性，减少攻击面。

noexec可以防止可移动设备上文件被直接执行，如病毒文件，攻击脚本等；

nodev可以防止可移动设备上不正确的设备文件链接到服务器真实设备，从而导致攻击行为；

常见的可移动设备如：CD/DVD/USB等。

**规则影响：**

可移动设备如果以noexec方式挂载，那么该挂载点目录下的可执行文件无法直接运行。


**检查方法：**

通过mount命令查看指定挂载点目录是否以noexec、nodev方式挂载，此处假设/dev/vda为可移动设备：

```bash
# mount | grep "\/dev\/vda"
/dev/vda on /root/noexecdir type ext4 (rw,nodev,noexec,relatime,seclabel)
```

**修复方法：**

卸载对应挂载点，重新以nodev、noexec方式挂载

```bash
# umount /root/noexecdir
# mount -o nodev,noexec /dev/vda /root/noexecdir
```
### 1.1.12 确保无需SUID/SGID的分区以nosuid方式挂载

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

可执行文件设置SUID位后，即使执行该文件的用户并不是文件的属主，在执行过程中，该进程也会被暂时赋予文件属主的权限。例如普通用户test执行一个权限为755，属主为root的程序，那么如果该程序没有设置SUID位，进程就只有test用户的权限；如果被设置了SUID，执行过程中，进程就拥有root的权限。SGID是类似的功能，只不过是拥有了文件属组的权限。对于不需要有SUID/SGID的分区采用nosuid的方式挂载，这样可以使该分区带SUID/SGID的文件的S位失效，防止通过该分区的可执行文件进行提权，加强了分区的安全性。

用户需要根据实际场景，规划各挂载硬盘和分区，设置nosuid挂载项。

**规则影响：**

无

**检查方法：**

通过mount命令检查文件系统是否以nosuid方式挂载，该命令返回未使用nosuid方式挂载的硬盘或分区，如下例中返回的挂载点均为系统默认挂载点（部分目录因硬盘分区，部署平台而不同），均需要suid功能，如果命令执行后存在与实际场景相关的目录，需要具体分析该目录是否挂载正确：

```bash
# mount | grep -v "nosuid"
/dev/mapper/openeuler-root on / type ext4 (rw,relatime,seclabel)
selinuxfs on /sys/fs/selinux type selinuxfs (rw,relatime)
systemd-1 on /proc/sys/fs/binfmt_misc type autofs (rw,relatime,fd=33,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=16986)
hugetlbfs on /dev/hugepages type hugetlbfs (rw,relatime,seclabel,pagesize=2M)
/dev/sda2 on /boot type ext4 (rw,relatime,seclabel)
/dev/sda1 on /boot/efi type vfat (rw,relatime,fmask=0077,dmask=0077,codepage=437,iocharset=ascii,shortname=winnt,errors=remount-ro)
/dev/mapper/openEuler-home on /home type ext4 (rw,relatime,seclabel)
sunrpc on /var/lib/nfs/rpc_pipefs type rpc_pipefs (rw,relatime)
```

**修复方法：**

* 卸载对应挂载点，重新以nosuid方式挂载：

  ```bash
  # umount /root/nosuid
  # mount -o nosuid /dev/vda /root/nosuid/
  ```

*  如果硬盘或分区是通过/etc/fstab配置文件进行挂载的，那么通过修改该文件，为指定挂载点添加nosuid挂载方式，如：

  ```bash
  # vim /etc/fstab
  /dev/vda /root/nosuid ext4 nosuid 0 0
  ```
### 1.1.13 确保删除文件不必要的SUID和SGID位

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

在Linux中，SUID（Set User ID）和 SGID（Set Group ID）是在UNIX和类UNIX操作系统中用于控制程序权限的特殊权限位，确保文件不包含不必要的SUID和SGID位非常重要，以提高系统的安全性。这些位允许文件在执行时以文件所有者或文件所属组的权限运行，可能会导致潜在的安全风险

**规则影响：**

无

**检查方法：**

可使用如下命令查找系统中的SUID和SGID文件，如果无返回，表示不存在该类文件：

```bash
# find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \;
null
```

**修复方法：**

找到SUID或SGID文件，需要审查这些文件并确定是否确实需要这些权限。通常，只有一些特定的系统工具或程序需要SUID或SGID权限，而绝大多数文件不需要。

如果确定某个文件不需要SUID或SGID权限，可以将其文件删除或移除文件的SUID和SGID位，执行命令行如下：

```bash
# rm -rf /path/to/file
或
# chmod u-s,g-s /path/to/file
```
### 1.1.14 确保关键文件、目录权限最小化

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

按照权限最小化要求，系统中的关键文件，特别是包含有敏感信息的文件，必须设置正确的最小的访问权限，只能有相应权限的用户可以访问，目录也是同样要求。文件或目录权限配置不正确，可能导致包含敏感数据的文件信息泄露，例如访问权限设置大于等于644，任何用户都可以访问，甚至篡改；只有root用户可以执行的程序，但却设置了755的权限，导致任何用户都可以执行，引入提权风险。

常见的需要做访问权限控制的文件或目录类型有：

* 可执行文件（二进制文件、脚本），存放可执行文件的目录。如果权限配置不当可能会导致提权攻击。

* 配置文件、密钥文件、日志文件、存储有敏感信息的数据文件、系统运行时产生的临时文件、静态文件等。这些文件中可能会含有敏感数据、隐私数据，如果权限配置不当会增加信息泄露的风险。

权限控制基本原则如下：

| 文件类型                           | 设置值           |
| ---------------------------------- | ---------------- |
| 用户主目录                         | 750（rwxr-x---） |
| 程序文件(含脚本文件、库文件等)     | 550（r-xr-x---） |
| 程序文件目录                       | 550（r-xr-x---） |
| 配置文件                           | 640（rw-r-----） |
| 配置文件目录                       | 750（rwxr-x---） |
| 日志文件(记录完毕或者已经归档)     | 440（r--r-----） |
| 日志文件(正在记录)                 | 640（rw-r-----） |
| 日志文件目录                       | 750（rwxr-x---） |
| Debug文件                          | 640（rw-r-----） |
| Debug文件目录                      | 750（rwxr-x---） |
| 临时文件目录                       | 750（rwxr-x---） |
| 维护升级文件目录                   | 770（rwxrwx---） |
| 业务数据文件                       | 640（rw-r-----） |
| 业务数据文件目录                   | 750（rwxr-x---） |
| 密钥组件、私钥、证书、密文文件目录 | 700（rwx—----）  |
| 密钥组件、私钥、证书、加密密文     | 600（rw-------） |
| 加解密接口、加解密脚本             | 500（r-x------） |

鉴于进程权限最小化原则，系统执行任务时一般使用非root的普通用户，该用户需要访问Linux系统中必要的目录和文件，所以对于系统本身运行依赖的系统目录、配置文件、可执行文件、证书文件，相应权限可适当放宽权限控制，建议如下：

| 文件类型                         | 设置值           |
| -------------------------------- | ---------------- |
| 目录                             | 755（rwxr-xr-x） |
| 程序文件（含脚本文件、库文件等） | 755（rwxr-xr-x） |
| 配置文件                         | 644（rw-r--r--） |
| 证书文件（无私钥）               | 444（r--r--r--） |

常见的需要做访问权限控制的文件的建议权限如下：

| 文件名称                         | 设置值           |
| -------------------------------- | ---------------- |
| /etc/passwd                     | 0644（-rw-r--r--） |
| /etc/group                      | 0644（-rw-r--r--） |
| /etc/shadow                      | 0000（----------） |
| /etc/gshadow                      | 0000（----------） |
| /etc/passwd-                      | 0644（-rw-r--r--） |
| /etc/shadow-                      | 0000（----------） |
| /etc/group-                      | 0644（-rw-r--r--） |
| /etc/gshadow-                      | 0000（----------） |
| /etc/ssh/sshd_config               | 0600（-rw-------） |

**规则影响：**

权限配置不能过大，也不能过小，例如有些系统配置文件，如果将权限设置为600或640，那么普通用户就无法读取，相应的程序可能因为无权读取配置而无法执行。

**检查方法：**

使用ll命令或ls -l命令查看文件权限：

```bash
# ls -l test
-rwxr-sr-t. 1 root root 33 Nov  5 14:44 test
```

**修复方法：**

使用chmod命令修改文件权限：

```bash
# chmod 750 test
# ll test
-rwxr-x---. 1 root root 33 Nov  5 14:44 test
```
### 1.1.15 确保用户可打开文件数量配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

在Linux系统中可以打开的文件总数是有限制的，如果全部资源被某个用户会话占用，其他用户将无法正常打开文件。

openEuler默认限制每个用户会话最多打开文件句柄数为1024，超过这个数会禁止打开新文件句柄。用户可以修改当前会话的最大允许值，但不能超过管理员设置的Hard上限（openEuler默认524288），root管理员可以修改该上限值，没有限制。用户可根据自身业务特点，设置合理的数值，防止单个用户会话的所有进程打开过多的文件句柄，耗尽系统资源。
可以通过ulimit命令进行设置，主要有两个参数：
* -Hn，该参数用于查看或设置上限最大值，这个值对于普通用户会话而言，一旦设定以后，只能调小，不能调大，比如第一次设置为3000（不能超过管理员设置的系统最大值，比如524288），那么后续设置只能为小于等于3000；
* -Sn，该参数用于查看或设置当前上限值，这个值是实际用于打开句柄数判断的值，这个值可以任意调大或调小，但不能超过-Hn设置的上限最大值。

普通用户进行设置，均只作用于当前会话。

**规则影响：**

设置过小，可能导致用户在当前会话中无法打开必要的文件句柄，设置过大可能导致系统资源耗尽。

**检查方法：**

* 查看当前限制值：

  ```bash
  # ulimit -Sn
  1024
  ```

* 查看普通用户可修改的上限值：

  ```bash
  # ulimit -Hn
  524288
  ```

**修复方法：**

* 可以通过修改/etc/security/limits.conf文件配置每个用户默认的上限和上限最大值，比如加入如下行：
  ```bash
  用户名 hard nofile 10000
  用户名 soft nofile 2000
  ```
* 可以在会话中使用ulimit命令进行临时设置。

  普通用户设置上限2000：

  ```bash
  $ ulimit -Sn 2000
  ```

  普通用户设置上限最大值5000（不能超过原上限最大值）：

  ```bash
  $ ulimit -Hn 5000
  ```

  同时设置上限和上限最大值，可以使用如下命令：

  ```bash
  $ ulimit -n 3000
  ```

  root用户设置上限以及上限最大值的方法同普通用户一样，但root用户可以将上限最大值设置为大于openEuler默认值524288：

  ```bash
  # ulimit -Hn 1000000
  # ulimit -Hn
  1000000
  ```
### 1.1.16 确保软、硬链接文件保护配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

在Linux系统中，软、硬链接文件是一个文件链接到另一个目标文件，打开该链接文件其实就是打开目标文件。所以，攻击者以低权限用户伪造的软链接文件，可以被高权限用户执行，导致提权安全问题。硬链接文件有同样问题。

本规则要求系统中对软、硬链接进行加固，如果目标文件和链接文件不是同属主的，且链接文件属主无权执行目标文件的，无论访问该链接的用户是谁，均拒绝访问。

这里就会存在一种竞争风险，如果一个高权限进程需要在/tmp目录（一般在全局可写目录下创建的文件容易被利用攻击，因为其他目录权限控制比较严格）创建一个临时文件A，可能的操作是先判断文件是否存在，如果不存在，就创建并打开。此时，攻击者可以在判断之后，创建之前，利用这个时间间隙创建一个同临时文件A同名的软链接文件到系统关键文件B（需要高权限管理员才能访问），此时，高权限进程创建并访问文件A，其实就相当于直接访问了文件B，原本攻击者对文件B没有权限，但利用高权限进程，访问到了文件B，通过该进程，可以对文件B进行破坏、篡改、数据窃取。

可以看到在这个案例中，原本文件A和B的属主应该都是root，但因为存在竞争攻击，A的属主变成了攻击者普通用户，临时文件变成了链接文件，B依旧是root属主，结果只要高权限进程有文件B的权限，就可以通过A这个软链接文件访问B。

openEuler默认已经设置软、硬链接保护。

**规则影响：**

无

**检查方法：**

使用如下命令检查，如果返回值为1，表示已经启用保护：

```bash
# sysctl fs.protected_symlinks
fs.protected_symlinks = 1
# sysctl fs.protected_hardlinks
fs.protected_hardlinks = 1
```

**修复方法：**

openEuler默认已经启用保护，无需设置。

* 如果因实际场景需要启、闭保护状态，可使用如下命令临时设置，重启后恢复默认值：

  启用保护

  ```bash
  # sysctl -w fs.protected_symlinks=1
  fs.protected_symlinks = 1
  # sysctl -w fs.protected_hardlinks=1
  fs.protected_hardlinks = 1
  ```

  关闭保护

  ```bash
  # sysctl -w fs.protected_symlinks=0
  fs.protected_symlinks = 0
  # sysctl -w fs.protected_hardlinks=0
  fs.protected_hardlinks = 0
  ```

* 可以通过修改/etc/sysctl.conf文件，添加如下代码，并执行# sysctl -p /etc/sysctl.conf，实现永久启、闭保护状态：

  启用保护

  ```bash
  # vim /etc/sysctl.conf
  fs.protected_symlinks = 1
  fs.protected_hardlinks = 1
  ```

  关闭保护

  ```bash
  # vim /etc/sysctl.conf
  fs.protected_symlinks = 0
  fs.protected_hardlinks = 0
  ```
### 1.1.17 避免使用USB存储

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

USB存储设备通常用于在服务器之间拷贝数据，但由于USB存储设备上的数据一般情况下无法通过技术手段保护，增加了被攻击的风险。如果USB设备上存在病毒、木马等攻击程序，将可能导致服务器被感染破坏，如果USB存储设备管理不善，将导致数据泄露。所以攻击者可以通过构造、破坏USB存储数据，再利用合法的管理人员在服务器上操作USB存储设备，达到攻击服务器、窃取数据的目的。建议根据实际场景，禁用USB存储。

**规则影响：**

无法使用USB存储数据

**检查方法：**

使用如下命令检查输出结果，如果输出“install /bin/true”，表示USB存储设备已经被禁止使用；如果输出“insmod /lib/modules/(kernel version)/kernel/drivers/usb/storage/usb-storage.ko.xz”，表示未被禁止，并列出ko所在目录：

```bash
# modprobe -n -v usb-storage
install /bin/true
```

**修复方法：**

在/etc/modprobe.d/目录下，添加一个任意文件名的，并以.conf为后缀的配置文件，属主和属组均为root, 权限600，按照如下格式填入代码，即可禁用USB存储：

```bash
# vim /etc/modprobe.d/test.conf
install usb-storage /bin/true
```
### 1.1.18 应当分区管理硬盘数据

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

在安装操作系统时，应根据实际场景特点，将操作系统数据同业务数据分区管理，避免将所有数据放在一个硬盘或分区下，合理规划硬盘分区可以避免或降低如下风险：

* 日志文件过大，导致业务或系统数据盘满；
* 普通账号home目录过大，导致系统或业务盘满；
* 系统分区不独立，导致盘满后，操作系统基础服务故障，引起全面DOS攻击；
* 不利于权限最小化控制，不利于数据盘加密；
* 盘损坏后不利于系统或数据恢复。

openEuler作为通用操作系统，默认安装单独分区“/boot、/tmp、/home、/”，建议根据实际场景确定其他目录的分区挂载以及大小。

**规则影响：**

无

**检查方法：**

通过如下命令检查指定目录是否挂载合理，具体目录清单可根据实际情况增减，如果返回为空，表示这些目录都没有单独挂载分区，否则返回挂载列表：

```bash
# df | grep -iE "/boot|/tmp|/home|/var|/usr"
```

**修复方法：**

根据实际使用场景对硬盘进行合理划分，建议如下：

* 操作系统中的“/boot、/home、/tmp、/usr、/var”目录，建议在系统安装部署时同根目录“/”分开，单独分区挂载，并安装系统文件，其中“/tmp”目录一般挂载为tmpfs格式的临时内存文件系统，如果关机后用户业务不需要保持“/tmp”目录下文件持久化，可以不指定硬盘分区，操作系统自动挂载tmpfs文件系统；
* 业务数据目录建议单独分区或独立硬盘、磁阵挂载；
* 本地转储（或保存）的日志，建议单独分区或硬盘、磁阵挂载；
* 合理分配各个分区的空间大小。

对于数据盘，可以通过mount命令进行临时挂载，例如：

```bash
# mount /dev/sdb /mnt/data
```

也可以修改/etc/fstab文件，确保下次重启后自动挂载：

```bash
# echo "/dev/sdb /home/test ext4 defaults 1 1" >> /etc/fstab
```
### 1.1.19 确保LD_LIBRARY_PATH变量定义正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

LD_LIBRARY_PATH是Linux的环境变量，程序加载动态链接库时，会优先从该环境变量指定的路径中获取。通常情况下该环境变量不应该被设置，如果被恶意设置为不正确的值，程序在运行时就有可能链接到不正确的动态库，导致安全风险。
注：/etc/ld.so.conf.d中配置也会影响动态库加载，需要确保正确配置。

openEuler默认不设置该变量，根据实际场景，如果必须设置LD_LIBRARY_PATH，需确保在所有用户上下文中该值都是正确的。

**规则影响：**

无

**检查方法：**

* 有多个配置文件可以永久设置LD_LIBRARY_PATH值，需要进行排查，这些文件包括：/etc/profile、~/.bashrc、~/.bash_profile，后两个文件为用户home目录下的文件，每个用户都有，检查时务必不能遗漏。

  使用grep命令进行检查，举例中发现/etc/profile文件中设置了LD_LIBRARY_PATH值：

  ```bash
  # grep "LD_LIBRARY_PATH" /etc/profile ~/.bashrc ~/.bash_profile
  /etc/profile:export LD_LIBRARY_PATH=/home/
  ```

* 检查当前用户上下文中是否存在LD_LIBRARY_PATH值，如果未设置LD_LIBRARY_PATH，则echo命令执行完以后打印为空，否则打印出当前设置的LD_LIBRARY_PATH值：

  ```bash
  # echo $LD_LIBRARY_PATH
  /home/
  ```

**修复方法：**

删除所有配置文件中LD_LIBRARY_PATH配置项，或将其设置为正确值。
### 1.1.20 确保用户PATH变量被严格定义

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

Linux下PATH变量定义的是当前用户上下文中可执行文件查找路径，例如：用户在任意目录下使用ls命令，那么系统会在PATH变量指定的目录下查找ls命令，找到后执行。所有用户上下文中的PATH变量不能包含当前目录“.”。目录必须是在文件系统中真实存在、并符合系统的设计期望的路径。正确的PATH值，可以有效防止系统命令被恶意的指令替代，确保系统命令能够安全执行。

所以PATH变量应该被定义为正确的值，openEuler系统默认设置为：

/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

可以根据实际场景对PATH进行修改，但务必确保正确。

**规则影响：**

无

**检查方法：**

通过echo命令可以打印出当前用户上下文中PATH的值，检查是否正确，openEuler root用户上下文中PATH值如下：

```bash
# echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
```

openEuler普通用户test上下文中PATH值如下：

```bash
# echo $PATH
/usr/local/bin:/usr/bin
```

**修复方法：**

PATH环境变量分为两部分，一部分在/etc/profile文件中设置，一部分在用户目录下.bashrc或.bash_profile文件中设置，前者影响所有用户，后者只影响当前用户。

所以可以通过修改这两个文件中PATH相关字段代码，即可永久修改系统PATH变量值，例如：

```bash
# vim /etc/profile
export PATH=$PATH:<attach new path>
```

如果只是临时修改当前会话的PATH值，可以执行如下命令，会话关闭后失效：

```bash
# export PATH=$PATH:<attach new path>
或
# export PATH=<the whole of new path>
```
## 1.2 软件
### 1.2.1 禁止安装FTP客户端

**级别：** 要求

**适用版本：** 全部

**规则说明：** 
FTP（File Transfer Protocol，文件传输协议），提供Linux服务器同其他服务器、桌面系统、终端设备之间的文件传输功能。FTP协议本身不支持加密传输，数据传输过程中容易被攻击者窃取，所以禁止安装FTP客户端，并使用FTP协议。未安装FTP客户端的设备，无法对外通过FTP协议进行传输，如业务需要进行文件传输，可以通过SFTP进行替代。

**规则影响：**

未安装FTP客户端，将无法同FTP服务器进行协议连接。

**检查方法：**

可通过如下命令检查是否安装了FTP软件，如果命令返回为"package ftp is not installed"，表示未安装：

```bash
# rpm -q "ftp"
package ftp is not installed
```

**修复方法：**

对于已经安装了FTP软件的系统，可以通过yum或dnf命令进行卸载：

```bash
# yum remove ftp
```
或
```bash
# dnf remove ftp
```

### 1.2.2 禁止安装TFTP客户端

**级别：** 要求

**适用版本：** 全部

**规则说明：** 
TFTP（Trivial File Transfer Protocol，简单文件传输协议），提供Linux服务器同其他服务器、桌面系统、终端设备之间的文件传输功能。TFTP协议本身不支持认证和加密机制，通信过程中容易被攻击者仿冒、篡改、以及窃取，所以禁止安装TFTP客户端和服务。未安装TFTP客户端和服务的设备，无法对外提供TFTP服务，也无法使用客户端同外界基于TFTP协议进行通信，如业务需要进行文件传输，可以通过SFTP服务进行替代。

**规则影响：**

依赖于TFTP服务的程序执行受限制。

**检查方法：**

可通过如下命令检查是否安装了TFTP软件，如果命令返回“package tftp is not installed”，表示未安装：

```bash
# rpm -q "tftp"
package tftp is not installed
```

**修复方法：**

对于已经安装了TFTP软件的系统，可以通过yum或dnf命令进行卸载：

```bash
# yum remove tftp tftp-server
```
或
```bash
# dnf remove tftp tftp-server
```

### 1.2.3 禁止安装Telnet客户端

**级别：** 要求

**适用版本：** 全部

**规则说明：** 
Telnet是一种应用层协议，常用于服务器的远程登录、操作控制、系统修改等；Telnet传输数据未被加密，用户名、口令、传输数据等容易被攻击者窃取，所以应禁止安装和使用Telnet客户端工具，可以使用基于ssh协议的客户端工具进行替代。

**规则影响：**

依赖于Telnet服务的程序执行受限制。

**检查方法：**

可通过如下命令检查是否安装了Telnet客户端软件，如果命令返回“package telnet is not installed”，表示未安装：

```bash
# rpm -q "telnet"
package telnet is not installed
```

**修复方法：**

对于已经安装了Telnet软件的系统，可以通过yum或dnf命令进行卸载：

```bash
# yum remove telnet
```
或
```bash
# dnf remove telnet
```

### 1.2.4 禁止安装不安全的SNMP协议版本

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

简单网络管理协议（SNMP，Simple Network Management Protocol），是专门设计用于在IP网络中管理网络节点的一种标准协议，该协议允许网元之间传递相关网络管理、控制数据。对于不需要SNMP的场景，如果安装了SNMP，则增加了系统资源消耗，并扩大了攻击面，特别是如果使用了SNMP v1.0协议，将导致攻击者可以轻易窃取、篡改、伪造SNMP报文，对各网元进行攻击。

openEuler安装镜像中提供了net-snmp安装包，但默认未安装。

**规则影响：**

依赖于SNMP服务的程序执行受限制。

**检查方法：** 

可通过如下命令检查是否安装了snmp软件，如果命令返回为空，则表示未安装：

```bash
# rpm -qa | grep -E "net-snmp-[0-9]"
```

**修复方法：** 

对于已安装snmp组件的服务器，可以通过yum或dnf命令进行卸载：

```bash
# yum remove net-snmp
```
或
```bash
# dnf remove net-snmp
```
### 1.2.5 禁止安装python2

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

python2 社区已经于2020年1月1日停止维护与改进。继续使用该软件容易扩大系统攻击面，增加系统漏洞和被攻击风险，所以禁止使用python2。若有使用python的诉求，建议使用主流版本以减小安全风险。

openEuler安装镜像中不提供python2相关软件包。

**规则影响：**

依赖于python2的程序执行受限制。

**检查方法：**

可通过如下命令检查是否安装了python2软件，如果命令返回为空，则表示未安装：

```bash
# rpm -qa | grep "python2-"
```

**修复方法：** 

对于已安装python2组件的服务器，可以通过yum或dnf命令进行卸载：

```bash
# yum remove python2
```
或
```bash
# dnf remove python2
```

### 1.2.6 确保yum源配置GPG校验

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

安装包在网络传输或本地存储时存在被攻击者恶意篡改的可能，若未对安装包进行完整性校验，则可能安装了攻击者篡改后的软件，导致服务器甚至整个网络集群遭受攻击。如果使用repo源进行操作系统软件安装升级，必须配置GPG校验。

openEuler支持使用dnf或yum命令从repo源下载、安装或升级rpm包，通过/etc/yum.repo.d目录下的文件进行repo源配置，必须配置GPG校验，在系统中必须已安装GPG公钥，或者在repo源配置文件中指定公钥下载地址。

GPG公钥是校验RPM包合法性的关键，请确保安装可信的GPG公钥。

**规则影响：**

无GPG的repo源无法正常使用。

**检查方法：**

检查系统中是否已经加载GPG公钥，如果返回为空，表示未安装公钥，如果有不同的repo源配置，可能会有多个不同的公钥返回：

```bash
# rpm -qa gpg-pubkey*
gpg-pubkey-e2ec75bc-5c78bcae
```

检查repo源配置文件中是否包含有“gpgcheck=1”字段，如果有多个配置文件，则每个配置文件都应该设置该字段：

```bash
# grep -iE "^gpgcheck[ ]*=[ ]*1" /etc/yum.repos.d/ -rn
/etc/yum.repos.d/base.repo:6:gpgcheck=1
```

检查repo源配置文件中是否已配置公钥下载地址（如果系统中已经安装有对应repo源的公钥，则不是必须配置）：

```bash
# grep -iE "^gpgkey" /etc/yum.repos.d/ -rn
/etc/yum.repos.d/base_tmp.repo:7:gpgkey=<repo源GPG公钥地址>
```

**修复方法：**

openEuler所有商用发布的rpm包都经过GPG私钥签名，通过rpm命令进行安装时会校验签名是否合法，如果校验不通过，可以安装，但会给出告警提示（如下）。禁止通过添加--nosignature --nodigest等方式跳过签名和完整性校验。

```bash
# rpm -ivh keyutils-<version numbers>.rpm
warning: keyutils-<version numbers>.rpm: Header V4 RSA/SHA256 Signature, key ID e2ec75bc: NOKEY
Verifying...            ################################# [100%]
Preparing...            ################################# [100%]
Updating / installing...
   1:keyutils-<version numbers>  ################################# [100%]
```

通过repo源进行rpm包安装时，必须在repo源配置文件中添加gpgcheck=1字段，开启GPG校验，并添加正确的GPG公钥下载地址：

```bash
# vim /etc/yum.repos.d/base.repo
[Euler]
name=Euler
baseurl=<repo源地址>
gpgkey=<repo源GPG公钥地址>
enabled=1
priority=1
gpgcheck=1
```

如果repo配置文件中不包含GPG公钥下载地址，则必须通过rpm命令安装对应源的公钥，如果有多个repo源，则每个repo源可能有不同的GPG公钥，需要分别安装：

```bash
# rpm --import ./key
```
### 1.2.7 禁止启用debug-shell服务

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

debug-shell 服务主要是用来定位系统引导过程中出现的问题，该服务随systemd安装而被安装。开启debug-shell服务后可以在系统启动过程中，systemd启动阶段按下ctrl + alt + F9，攻击者不需要认证直接进入root shell。该过程安全风险很高，攻击者可以通过篡改数据，执行非法程序等手段破坏系统。

openEuler默认禁止启动debug-shell服务。

**规则影响：**

无

**检查方法：**

检查是否启动了服务，如果命令返回为disable，则表示服务未启动：

```bash
# systemctl is-enabled debug-shell
disabled
```

**修复方法：**

对于已安装debug-shell组件的服务器，可以禁用debug-shell服务：

```bash
# systemctl --now disable debug-shell
```
### 1.2.8 禁止安装rsync服务

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

rsync服务可以用于在服务器之间或者服务器本地不同硬盘分区之间同步数据，但由于rsync使用不加密的传输协议，存在信息泄露的风险。若启用rsync服务，并且在不同服务器之间通过网络传输数据，则攻击者可以通过监听服务器端口或者路由器、交换机数据报文，窃取数据。

openEuler安装镜像中提供了rsync安装包，要求在生产环境中不启动rsync服务。

**规则影响：**

依赖于rsync服务的程序执行受限制。

**检查方法：**

步骤1：

检查是否安装了rsync软件，如果命令返回为空，则表示未安装，符合规范要求，检查结束，否则继续执行步骤2。

```bash
# rpm -qa | grep "rsync"
```

步骤2：

安装了rsync软件时，检查rsync服务是否开启，disabled表示未启用服务，符合规范要求：

```bash
# systemctl is-enabled rsyncd
disabled
```

**修复方法：**

对于已安装rsync组件的服务器，可以禁用rsyncd服务：

```bash
# systemctl --now disable rsyncd
```
### 1.2.9 禁止安装avahi服务

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

avahi是一种零配置的网络实现，包括用于多播DNS/DNS-SD服务的自动发现及自动广播。例如，用户可以将服务器接入网络，并让avahi自动广播其上运行的网络服务，从而方便其他用户访问这些服务。通常并不需要自动发现或者自动广播业务，如果启用不必要的avahi服务，不仅浪费了系统资源，还扩大了攻击面，攻击者可以轻易获取服务器服务情况，并进行针对性的攻击。

**规则影响：**

依赖于avahi服务的程序执行受限制。

**检查方法：**

检查是否安装了avahi软件，如果命令返回为空，则表示未安装：

```bash
# rpm -qa | grep "avahi"
```

注意，由于其他组件依赖，系统默认安装有avahi-libs。同时，可以通过systemctl命令检查是否安装avahi服务（如下返回表示未启动，且未安装avahi服务）：

```bash
# systemctl is-enabled avahi-daemon
Failed to get unit file state for avahi-daemon.service: No such  file or directory
```

**修复方法：**

对于已安装avahi组件的服务器，可以通过yum或dnf命令进行卸载：

```bash
# yum remove avahi
```
或
```bash
# dnf remove avahi
```
### 1.2.10 禁止安装LDAP服务

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

LDAP（Lightweight Directory Access Protocol，轻型目录访问协议）是一个轻量级的目录访问协议，提供访问控制和维护分布式的目录信息。系统提供LDAP服务会增加系统资源占用，且扩大了攻击面，如果用户业务场景不需要提供LDAP服务，则禁止安装LDAP服务。

openEuler安装镜像中提供了openldap-servers安装包，但默认未安装。

**规则影响：**

依赖于LDAP服务的程序执行受限制。

**检查方法：**

检查是否安装了openldap-servers软件，如果命令返回为空，则表示未安装：

```bash
# rpm -qa | grep "openldap-servers"
```

**修复方法：**

对于已安装openldap-servers组件的服务器，可以通过yum或dnf命令进行卸载：

```bash
# yum remove openldap-servers
```
或
```bash
# dnf remove openldap-servers
```
### 1.2.11 禁止安装打印服务

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

CUPS（Common Unix Printing System，Unix通用打印系统），启用该服务的服务器为网络内其他设备提供打印服务。提供CUPS服务会占用系统资源，并扩大攻击面。如果业务场景不需要提供打印服务，则禁止安装打印服务。

openEuler安装镜像中提供了CUPS相关的安装包，但默认未安装。

**规则影响：**

依赖于CUPS服务的程序执行受限制。

**检查方法：**

检查是否安装了CUPS软件，如果命令返回为空，则表示未安装：

```bash
# rpm -qa cups
```

**修复方法：**

对于已安装CUPS组件的服务器，可以通过yum或dnf命令进行卸载：

```bash
# yum remove cups
```
或
```bash
# dnf remove cups
```
### 1.2.12 禁止安装NIS服务端

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

NIS（Network Information Service，网络信息服务），以客户端/服务器形式存在，客户端（ypbind）从服务器获取分发的配置信息。NIS服务本质上是一个不安全的服务，容易受到DOS、缓冲区溢出等攻击。如果业务不涉及NIS服务，禁止安装NIS服务端。

openEuler安装镜像中提供了NIS服务端安装包（ypserv），但默认未安装。

**规则影响：**

依赖于NIS服务的程序执行受限制。

**检查方法：**

检查是否安装了ypserv软件，如果命令返回为空，则表示未安装：

```bash
# rpm -qa | grep "ypserv"
```

**修复方法：**

对于已安装ypserv组件的服务器，可以通过yum或dnf命令进行卸载：

```bash
# yum remove ypserv
```
或
```bash
# dnf remove ypserv
```
### 1.2.13 禁止安装NIS客户端

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

NIS（Network Information Service，网络信息服务），以客户端/服务器形式存在，客户端（ypbind）从服务器获取分发的配置信息。NIS服务本质上是一个不安全的服务，容易受到DOS、缓冲区溢出等攻击。如果业务不涉及NIS服务，禁止安装并使用NIS客户端。

openEuler安装镜像中提供了ypbind安装包，但默认未安装。

**规则影响：**

依赖于NIS服务的程序执行受限制。

**检查方法：**

检查是否安装了ypbind软件，如果命令返回为空，则表示未安装：

```bash
# rpm -qa | grep "ypbind"
```

**修复方法：**

对于已安装ypbind组件的服务器，可以通过yum或dnf命令进行卸载：

```bash
# yum remove ypbind
```
或
```bash
# dnf remove ypbind
```
### 1.2.14 禁止安装LDAP客户端

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

LDAP（Lightweight Directory Access Protocol，轻型目录访问协议）是一个轻量级的目录访问协议，提供访问控制和维护分布式的目录信息。系统提供LDAP客户端会造成系统资源浪费，且扩大了攻击面。如果业务场景不需要使用LDAP服务，则禁止安装LDAP客户端。

openEuler安装镜像中提供了openldap-clients安装包，但默认未安装。

**规则影响：**

依赖于LDAP服务的程序执行受限制。

**检查方法：**

检查是否安装了openldap-clients软件，如果命令返回为空，则表示未安装：

```bash
# rpm -qa | grep "openldap-clients"
```

**修复方法：**

对于已安装openldap-clients组件的服务器，可以通过yum或dnf命令进行卸载：

```bash
# yum remove openldap-clients
```
或
```bash
# dnf remove openldap-clients
```
### 1.2.15 禁止安装网络嗅探类工具

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

生产环境中如果包含有网络嗅探类工具，容易被攻击者利用这些工具进行网络分析，辅助网络攻击。所以应在生产环境中禁止安装各类网络嗅探、抓包分析类工具，例如tcpdump、ethereal、wireshark等。

**规则影响：**

无

**检查方法：**

编写脚本工具，在生产环境或镜像环境中通过关键字扫描来判断是否存在网络嗅探类工具，脚本中可以包含如下命令：

* 查找相关rpm包是否被安装，用户可根据自身场景，在此基础上添加需要检查的所有rpm包名（此处只是举例，实际包名及范围由用户确定），如果返回为空，表示未安装，否则返回已安装的rpm包列表：

  ```bash
  # rpm -qa | grep -iE "^(wireshark-|netcat-|tcpdump-|nmap-|ethereal-)"
  ```

* 查找相关命令是否被安装，用户可根据自身场景，在此基础上添加需要检查的所有命令名（此处只是举例，实际命令名及范围由用户确定），如果返回为空，表示未安装，否则返回已安装的命令列表：

  ```bash
  # files=`find / -type f \( -name "wireshark" -o -name  "netcat" -o -name "tcpdump" -o -name "nmap" -o  -name "ethereal" \) 2>/dev/null`;for f in $files;do if [ -n "$f" ];then file $f | grep -i "ELF" ;fi;done
  ```

**修复方法：**

如果用户业务环境中安装有网络嗅探类软件，需通过rpm命令查找并删除软件包，例如删除nmap：

```bash
# rpm -e nmap
```

或者通过rm命令手工删除nmap命令文件，但这种方式仅限于非rpm包方式安装的网络嗅探工具，且需确保删除所有相关文件：

```bash
# rm /usr/bin/nmap
```
### 1.2.16 禁止安装调测类工具

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

业务环境中如果包含有调测类脚本、工具，容易被攻击者利用并攻击。所以应在生产环境中严禁安装各类调测工具、文件，包括但不限于：代码调试工具，用于调测功能的提权命令、脚本、工具，调试阶段使用的证书、密钥，用于性能测试的perf工具、打点、打桩工具，用于CVE等安全问题验证的攻击脚本、工具脚本等。常见的开源第三方调测类工具包括：strace、gdb、readelf、perf等。

**规则影响：**

无

**检查方法：**

编写脚本工具，在业务环境或镜像环境中通过关键字扫描来判断是否存在调测类工具，脚本中可以包含如下命令：

* 查找相关rpm包是否被安装，用户可根据自身场景，在此基础上添加需要检查的所有rpm包名（此处只是举例，实际包名及范围由用户确定），如果返回为空，表示未安装，否则返回已安装的rpm包列表：

  ```bash
  # rpm -qa | grep -iE "^strace-|^gdb-|^perf-|^binutils-extra|^appict|^kmem_analyzer_tools"
  ```

* 查找相关命令是否被安装，用户可根据自身场景，在此基础上添加需要检查的所有命令名（此处只是举例，实际命令名及范围由用户确定），如果返回为空，表示未安装，否则返回已安装的命令列表：

  ```bash
  # find / -type f \( -name "gdb" -o -name  "perf" -o -name "strace" -o -name "readelf" \)
  ```

**修复方法：**

如果用户业务环境中安装有调测类软件，需通过rpm命令查找并删除软件包，例如删除gdb：

```bash
# rpm -e gdb
```

或者通过rm命令手工删除gdb命令文件，但这种方式仅限于非rpm包方式安装的调测工具，且需确保删除所有相关文件：

```bash
# rm /usr/bin/gdb
```
### 1.2.17 禁止安装开发编译类工具

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

业务环境中如果包含有编译工具，容易被攻击者利用，对环境内关键文件进行编辑篡改、逆向分析，从而实施攻击行为。所以应在生产环境中严禁安装各类编译、反编译、二进制分析类工具，包括但不限于：编译工具，反编译工具，编译环境等。常见的第三方开发编译类工具包括：gcc、cpp、mcpp、flex、cmake、make、rpm-build、ld、ar等。

如果业务环境在部署或运行过程中依赖python、lua、perl等解释器，则可以保留解释器运行环境。

**规则影响：**

无

**检查方法：**

编写脚本工具，在业务环境或镜像环境中通过关键字扫描来判断是否存在开发编译类工具，脚本中可以包含如下命令：

* 查找相关rpm包是否被安装，用户可根据自身场景，在此基础上添加需要检查的所有rpm包名（此处只是举例，实际包名及范围由用户确定），如果返回为空，表示未安装，否则返回已安装的rpm包列表：

  ```bash
  # rpm -qa | grep -iE "^(gcc-|cpp-|mcpp-|flex-|cmake-|make-|rpm-build-|binutils-extra|elfutils-extra|llvm-|rpcgen-|gcc-c++|libtool)"
  ```

* 查找相关命令是否被安装，用户可根据自身场景，在此基础上添加需要检查的所有命令名（此处只是举例，实际命令名及范围由用户确定），如果返回为空，表示未安装，否则返回已安装的命令列表：

  ```bash
  # files=`find / -type f \( -name "gcc" -o -name "g++" -o -name "c++" -o -name  "cpp" -o -name "mcpp" -o -name "flex" -o -name "lex" -o -name  "cmake" -o -name "make" -o -name "rpmbuild" -o  -name "ld" -o -name "ar" -o -name "llc" -o -name "rpcgen" -o -name "libtool" -o -name "javac" -o -name "objdump" -o -name "eu-objdump" -o -name "eu-readelf" -o -name "nm" \) 2> /dev/null`; for f in $files; do if [ -n "$f" ]; then file $f | grep -i "ELF"; fi; done
  ```

**修复方法：**

如果业务环境中安装有开发编译类软件，需通过rpm命令查找并删除软件包，例如删除gcc：

```bash
# rpm -e gcc
```

或者通过rm命令手工删除gcc命令文件，但这种方式仅限于非rpm包方式安装的开发编译工具，且需确保删除所有相关文件：

```bash
# rm /usr/bin/gcc
```
### 1.2.18 避免安装X Window系统

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

X Window在Linux系统中提供图形界面供用户登录和操作，通常情况下服务器场景无需图形界面，管理员通过命令行即可对服务器完成配置修改。X Window图形界面扩大了攻击面，不常用或相对小众的图形界面组件可能存在较多的软件缺陷，容易被攻击者利用，进而对系统进行破坏。另外，在无需图形界面的服务器上安装X Window组件，浪费了服务器资源，增加了维护成本

**规则影响：**

X Windows相关组件无法使用

**检查方法：**

检查是否安装了X Window相关组件，如果命令返回为空，则表示未安装：

```bash
# rpm -qa "xorg-x11"
```

**修复方法：**

对于已安装X Window组件的服务器，可以通过yum或dnf命令进行卸载：

```bash
# yum remove <package name>
或
# dnf remove <package name>
```
### 1.2.19 避免安装HTTP服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

HTTP代表超文本协议（Hypertext Transfer Protocol，HTTP）,是一个简单的请求-响应协议，它通常运行在TCP之上。它指定了客户端可能发送给服务器什么样的消息以及得到什么样的响应。请求和响应消息的头以ASCII形式给出；而消息内容则具有一个类似MIME的格式。HTTP服务器允许客户端（通常是浏览器）通过HTTP协议请求网页、图像、文档等Web内容，并将这些内容传送给客户端。

**规则影响：**

依赖于HTTP服务的程序执行受限制。

**检查方法：**

可通过如下命令检查是否安装了httpd客户端软件，如果命令返回“package httpd is not installed”，表示未安装：

```bash
# rpm -q "httpd"
package httpd is not installed
```

**修复方法：**

对于已经安装了httpd软件的系统，可以通过yum或dnf命令进行卸载：

```bash
# yum remove httpd
```
或
```bash
# dnf remove httpd
```
### 1.2.20 避免安装samba服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

samba守护进程允许系统管理员配置Linux系统以与windows桌面共享文件系统和目录。samba将通过服务器信息块（SMB）协议公布文件系统和目录。Windows桌面用户将能够将这些目录和文件系统作为盘符挂载在系统上。

**规则影响：**

与Windows系统进行文件共享或打印共享受限制。

**检查方法：**

可通过如下命令检查是否安装了samba软件，如果命令返回“package samba is not installed”，表示未安装：

```bash
# rpm -q "samba"
package samba is not installed
```

**修复方法：**

对于已经安装了samba软件的系统，可以通过yum或dnf命令进行卸载：

```bash
# yum remove samba
```
或
```bash
# dnf remove samba
```
### 1.2.21 避免启用DNS服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

域名系统(DNS)是一种分层命名系统，它将名称映射到计算机、服务和其它联网资源的IP地址。

除非系统被专门指定用作DNS服务器，否则建议禁用DNS Server以减少潜在的攻击面。

**规则影响：**

将无法作为域名服务器提供域名解析服务。

**检查方法：**

检查是否启动了服务，如果命令返回为disable，则表示服务未启动：

```bash
# systemctl is-enabled named
disabled
```

**修复方法：**

对于已安装named组件的服务器，可以禁用named服务：

```bash
# systemctl --now disable named
```
### 1.2.22 避免启用NFS服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

网络文件系统 (NFS) 是 UNIX 环境中最早也是分布最广泛的文件系统之一。它为系统提供了通过网络挂载其他服务器的文件系统的能力。如果系统不导出NFS共享，建议禁用NFS以减少远程攻击面。

**规则影响：**

禁用NFS会影响到系统上依赖NFS的服务和应用程序，以及现有的NFS挂载点。在禁用NFS之前，应确保了解系统上的使用情况，并考虑是否有替代方法来满足文件共享和数据访问的需求。

**检查方法：**

检查是否启动了服务，如果命令返回为disable，则表示服务未启动：

```bash
# systemctl is-enabled nfs-server
disabled
```

**修复方法：**

对于已安装nfs组件的服务器，可以禁用nfs-server服务：

```bash
# systemctl --now disable nfs-server
```


### 1.2.23 避免启用RPC服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

rpcbind服务将远程过程调用(RPC)服务映射到它们侦听的端口。RPC进程在启动时通知rpcbind，注册它们正在侦听的端口以及它们期望服务的RPC程序编号。然后，客户端系统使用特定的RPC程序号联系服务器上的rpcbind。rpcbind服务将客户端重定向到正确的端口号，以便它可以与请求的服务进行通信。

如果系统不需要基于 rpc 的服务，建议禁用 rpcbind 以减少远程攻击面。

**规则影响：**

无

**检查方法：**

检查是否启动了服务，如果命令返回为disabled，则表示服务未启动：

```bash
# systemctl is-enabled rpcbind
disabled
```

**修复方法：**

对于已安装rpcbind组件的服务器，可以禁用rpcbind服务：

```bash
# systemctl --now disable rpcbind
```
### 1.2.24 避免启用DHCP服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

动态主机配置协议（DHCP）是一项允许为机器动态分配IP地址的服务。

除非系统专门设置为充当DHCP Server，否则建议禁用该服务以减少潜在的攻击面。

**规则影响：**

无

**检查方法：**

检查是否启动了服务，如果命令返回为disabled，则表示服务未启动：

```bash
# systemctl is-enabled dhcpd
disabled
```

**修复方法：**

对于已安装dhcpd组件的服务器，可以禁用dhcpd服务：

```bash
# systemctl --now disable dhcpd
```
## 2 安全访问
## 2.1 账户
### 2.1.1 禁止无需登录的账号设置登录能力

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

通常情况下，Linux系统中存在多个账号，而这些账号并不一定都是需要登录的，例如systemd、dhcp等软件安装时会自带安装一些账号，这些账号只是为了运行相关的服务进程。对于无需进行登录的账号，必须禁止其登录能力。如果允许非登录账号有登录能力，将扩大攻击面，攻击者可以利用这些账号进行bash交互操作，从而攻击系统。

注意，sync、shutdown、halt属于特殊账号，通常情况下不能将shell设置为nologin或false，这几个账号在/shadow文件中口令设置为“*”，所以并不能直接登录。

openEuler默认满足无需登录的账号不具备登录能力。

**规则影响：**

无

**检查方法：** 

检查的目的是确认是否所有不该登录的账号都被设置了/sbin/nologin或/bin/false，或对应的口令被锁定。

- 使用如下命令查看/etc/passwd文件中非登录账号是否都已经被设置正确，命令执行后会列出所有设置了禁止登录的账号，可根据业务场景对这些账号进行比对：

  ```bash
  # cat /etc/passwd | grep "\/sbin\/nologin\|\/bin\/false" | awk -F ":" '{print $1}'
  ```

- 使用如下命令查看/etc/passwd文件中所有允许登录的账号，命令执行后会列出所有允许登录的账号，可根据业务场景对这些账号进行比对：

  ```bash
  # cat /etc/passwd | grep -v "\/sbin\/nologin\|\/bin\/false" | awk -F ":" '{print $1}'
  ```

- 如下命令执行后会列出所有口令被锁定的账号，可根据业务场景对这些账号进行比对：

  ```bash
  # cat /etc/passwd | awk -F ":" '{print $1}' | xargs -I '{}' passwd -S '{}' | awk '($2=="L" || $2=="LK") {print $1}' 
  ```

- 如下命令执行后会列出所有口令未被锁定的账号，可根据业务场景对这些账号进行比对：

  ```bash
  # cat /etc/passwd | awk -F ":" '{print $1}' | xargs -I '{}' passwd -S '{}' | awk '($2!="L" && $2!="LK") {print $1}'
  ```

**修复方法：** 

有两种方法可以锁定和解锁用户账号：

- 通过usermod命令修改/etc/passwd文件，将指定账号的登录shell设置为/sbin/nologin或/bin/false，该方法不仅可以防止用户登录，还可以防止使用su命令切换为指定用户账号，优先推荐该方法，操作如下（test为账号名）：

  锁定：

  ```bash
  # usermod -s /sbin/nologin test
  ```
  或
  ```bash
  # usermod -s /bin/false test
  ```
  解锁：

  ```bash
  # usermod -s /bin/bash test
  ```

- 修改/etc/shadow文件，在指定账号的第二个字段中添加感叹号“!”或“!!”，锁定口令，可通过如下命令操作（test为账号名，如果账号并未设置口令，则会提示操作失败）：

  锁定：

  ```bash
  # usermod -L test
  ```
  或
  ```bash
  # passwd -l test
  ```
  解锁：

  ```bash
  # usermod -U test
  ```
  或
  ```bash
  # passwd -u test
  ```

  使用usermod命令锁定的口令，可以使用passwd命令进行解锁，反之亦然。锁定或解锁后可以通过如下命令检查状态，LK表示口令已经锁定，NP表示口令未设置，PS表示口令已被设置，且未锁定：

  ```bash
  # passwd -S test
  test LK 2022-01-01 0 30 10 35 (Password locked.)
  ```
  或
  ```bash
  # passwd -S test
  test NP 2020-12-03 0 50 10 35 (Empty password.)
  ```
  或
  ```bash
  # passwd -S test
  test PS 2022-01-01 0 30 10 35 (Password set, SHA512 crypt.)
  ```
### 2.1.2 禁止存在不使用的账号

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

如果系统中存在业务无关的账号，容易被攻击者利用该账号进行攻击行为。系统应该只保留业务所必须的账号，其他用于安装部署、调试验证，以及问题定位等的账号都必须被删除。

openEuler默认满足不存在不使用的账号。

**规则影响：**

无

**检查方法：**

openEuler默认只保留系统运行必须的账号，根据自身业务场景确定是否存在业务无关账号，可以使用如下命令查找系统中所有账号：

```bash
# cat /etc/passwd | awk  -F ":" '{print $1}'  
```

按照以下步骤进行查询和判断：

- 在未部署业务的平台上，使用上述命令获取所有账号信息；
- 在完整部署业务的平台上，使用上述命令获取所有账号信息；
- 对比两者返回结果，对差异部分进行分析，是否符合业务设计。

**修复方法：**

如果存在业务无关账号，可通过如下步骤进行删除：

- 查找所有该账号为属主的文件，并通过rm命令手工删除这些文件，如下（test为账号名，/home/test目录在删除账号时可通过参数自动删除，xxx表示需要被删除的文件或目录）

  ```bash
  # find / -user test
  # rm xxx -rf
  ```

- 删除账号，包括home目录

  ```bash
  # userdel -rf test
  ```
### 2.1.3 确保不同账号初始分配不同的组ID

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

不同用户账号的初始登录组必须不同，如果某个用户账号需要访问其他组的文件，则需要通过命令明确指定加入该组。在大多数情况下，文件权限设置为640，文件夹设置为750，那么同组用户账号是可以对文件进行访问的，所以如果两个不相干的用户账号被设置为同一个组，存在文件被意外读取甚至篡改的可能。

openEuler默认满足不同账号初始分配不同的组ID。

**规则影响：**

无

**检查方法：**

检查/etc/passwd文件中各个账号所属的组id是否不同，可执行如下命令，如果没有相同组id，则命令执行后无输出，否则输出组id号以及相同组id的账号数量，如下面例子中输出1003 2，表示有两个账号的用户组id为1003：

```bash
# cat /etc/passwd | awk -F ":" '{a[$4]++}END{for(i in a){if(a[i]!=1 && i!=0){print i, a[i]}}}'
1003 2
```

注意：上面命令中过滤了root用户组，因为sync、shutdown等系统账号都属于root组，属于例外场景，在本规范中不做要求。

**修复方法：**

- 添加新账号时，不使用-g参数指定group，而是让系统直接自动分配新的group组，此处-U参数表示需要创建新用户组，默认可以不加：

  ```bash
  # useradd test
  ```
  或
  ```bash
  # useradd test
  ```
- 如果新账号需要被加入其它组，则可以通过-G参数指定，该命令为test1账号新建一个test1的组，作为test1账号默认登录组，另外会将test1账号加入用户组test：

  ```bash
  # useradd -G test test1
  ```

  通过如下命令检查test1同test的默认登录组不同：

  ```bash
  # cat /etc/passwd | grep test
  test:x:1007:1007::/home/test:/bin/bash
  test1:x:1008:1008::/home/test1:/bin/bash
  ```

  通过如下命令可以看到test1账号同时被加入了test组：

  ```bash
  # id test1
  uid=1008(test1) gid=1008(test1) groups=1008(test1),1007(test)
  ```

  test1账号登录后（或者su切换），可以通过newgrp命令切换到test组，命令执行后当前gid已经变成test组的id了，但这并不会改变/etc/passwd中的组id：

  ```bash
  # su test1
  $ newgrp test
  $ id
  uid=1008(test1) gid=1007(test) groups=1007(test),1008(test1) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
  ```

- 如果是已有账号，需要加入其他组，则可以通过如下命令操作

  ```bash
  # usermod -a -G root test1
  ```

  执行后，test1账号被加入到root组，查看结果如下：

  ```bash
  # id test1
  uid=1008(test1) gid=1008(test1) groups=1008(test1),0(root),1007(test)
  ```
### 2.1.4 禁止存在UID为0的非root账号

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

UID为0的账号是linux系统中的超级管理员账号，账号名业界约定俗成为root，系统中不允许存在非root账号的UID等于0。如果将root账号UID改为其他值，而其他账号test的UID改为0，那么就会导致账号test拥有超级管理员权限，主要有以下几个问题：

- 业界通用的安全扫描工具会认为账号test设置了非法UID；
- 增加管理成本，如果用户在使用test账号时没有意识到是超级管理员，可能因疏忽的缘故导致系统被破坏。

openEuler默认满足不存在UID为0的非root账号。

**规则影响：**

无

**检查方法：**

通过如下命令检查/etc/passwd文件中是否存在UID为0的非root账号，如下例子中命令执行后返回test 0，表示test账号的UID是0。如果没有UID为0的非root账号，命令无返回输出。

```bash
# cat /etc/passwd | awk -F ":" '{if($1!="root" && $3==0){print $1, $3}}'
test 0
```

**修复方法：**

直接修改/etc/passwd对应账号的UID字段，然后重启系统，需要确保修改的UID不能同其他账号重复。

注意：usermod命令可以修改账号UID，但如果被修改的账号UID原先为0，则会报错，因为UID为0的账号会被1号进程使用，所以只能通过手工方式直接修改/etc/passwd文件：

```bash
# usermod -u 2000 test
usermod: user test is currently used by process 1
```
### 2.1.5 确保账号、组及口令文件权限正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

Linux操作系统中用户账号、口令、用户组等认证相关信息都记录在/etc目录下的配置文件中，这些文件需要设置合理的访问权限，否则容易被攻击者窃取或篡改。

这些文件属主和属组必须为root和root组，对应的访问权限必须为：

| 文件          | 设置值           |
| ------------- | ---------------- |
| /etc/passwd   | 644（rw-r--r--） |
| /etc/shadow   | 000（---------） |
| /etc/group    | 644（rw-r--r--） |
| /etc/gshadow  | 000（---------） |
| /etc/passwd-  | 644（rw-r--r--） |
| /etc/shadow-  | 000（---------） |
| /etc/group-   | 644（rw-r--r--） |
| /etc/gshadow- | 000（---------） |

如果权限配置比表格中更加严格，则普通用户登录时可能无法读取passwd或group配置文件中的信息。导致登录或者执行操作失败。

如果权限配置比表格中更加宽松，则可能导致配置文件信息被攻击者窃取或篡改。

**规则影响：**

无

**检查方法：**

使用如下命令进行检查，如果返回信息同上表不符，则表示未满足权限要求：

```bash
# ll /etc/passwd
-rw-r--r--. 1 root root 1343 Dec  5 07:37 /etc/passwd
# ll /etc/shadow
----------. 1 root root 786 Dec  5 07:38 /etc/shadow
# ll /etc/group
-rw-r--r--. 1 root root 609 Dec 14 12:59 /etc/group
# ll /etc/gshadow
----------. 1 root root 485 Dec  5 07:37 /etc/gshadow
# ll /etc/passwd-
-rw-r--r--. 1 root root 1295 Dec  5 07:36 /etc/passwd-
# ll /etc/shadow-
----------. 1 root root 681 Dec  5 07:37 /etc/shadow-
# ll /etc/group-
-rw-r--r--. 1 root root 609 Dec  5 07:37 /etc/group-
# ll /etc/gshadow-
----------. 1 root root 474 Dec  5 07:36 /etc/gshadow-
```

**修复方法：**

如果文件权限不符合规范要求，可以通过chown和chmod命令进行修改：

```bash
# chown root:root <passwd/group/shadow config file>
# chmod <access permissions> <passwd/group/shadow config file>
```
### 2.1.6 确保账号拥有自己的Home目录

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

每个用户账号必须有自己的Home目录，用来存放账号相关的数据，该目录的属主必须是用户自身。如果Home目录属主不是自身，那么可能无法对该目录进行读写，或者该目录下保存的用户数据可以被其他用户（如属主）读取或篡改。如果没有Home目录，则用户账号登录后将无法获取到自身的环境配置数据。

openEuler默认满足每个账户拥有自己的Home目录。

**规则影响：**

无

**检查方法：**

使用如下脚本进行检查，如果无返回输出，则表示所有用户账号均有Home目录，目录属主正确：

```bash
#!/bin/bash  
 
grep -E -v '^(halt|sync|shutdown)' "/etc/passwd" | awk -F ":" '($7 != "/bin/false" && $7 != "/sbin/nologin" && $7 != "/usr/sbin/nologin") {print $1 " " $6}' | while read name home;
do
    if [ ! -d "$home" ]; then
        echo "No home folder \"$home\" of \"$name\"."
    else
            owner=`ls -l -d $home | awk -F " " '{print $3}'`
        if [ "$owner" != "$name" ]; then
            echo "\"$home\" is owned by $owner, not \"$name\"."
        fi
    fi
done
```

**修复方法：**

- 删除相应的用户账号：

  ```bash
  # userdel -r test
  userdel: test home directory (/home/test) not found
  ```

- 使用useradd命令添加用户账号（同时自动创建Home目录）：

  ```bash
  # useradd test
  # ll -d /home/test/
  drwx------. 2 test test 4096 Feb  2 13:19 /home/test/
  ```
### 2.1.7 确保/etc/passwd中的组都存在

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

要求在/etc/passwd中涉及到的用户组，都必须在/etc/group文件中真实存在。如果管理员通过手工方式修改这两个文件，则可能因为人为错误而导致用户组不正确。如果/etc/passwd中的用户组在/etc/group中不存在，那么将导致用户组权限管理风险。

**规则影响：**

无

**检查方法：**

使用如下脚本进行检查，如果无返回输出，则表示所有用户组设置正确：

```bash
#!/bin/bash
  
grep -E -v '^(halt|sync|shutdown)' "/etc/passwd" | awk -F ":" '($7 != "/bin/false" && $7 != "/sbin/nologin") {print $4}' | while read group;
do
    grep -q -P "^.*?:[^:]*:$group:" "/etc/group"
    if [ $? -ne 0 ]; then
        echo "Group $group not found"
    fi
done
```

**修复方法：**

分析两个文件不匹配的原因，可以有两种修复方式：

- 通过删除账号，重新添加的方式进行修复：

  ```bash
  # userdel -r test
  # useradd test
  ```

- 通过删除或添加组的方式进行修复（其中xxx表示gid的值）：

  ```bash
  # groupdel testgroup
  # groupadd -g xxx testgroup
  ```
### 2.1.8 确保UID唯一

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

要求在/etc/passwd中涉及到的用户账号UID唯一。Linux系统中根据UID来判断账号权限，如果多个账号使用同一个UID，则会导致这些账号拥有一样的权限，可以相互访问Home目录，以及各自创建的文件，导致越权以及信息泄露。

通常情况下使用useradd等命令添加用户账号，不会存在UID重复问题，但如果管理员操作失误，直接修改/etc/passwd文件，则可能导致问题。

**规则影响：**

无

**检查方法：**

使用如下命令进行检查，如果无返回输出，则表示所有UID设置正确，且唯一，否则列出UID和对应的复用次数，如3003这个UID被两个账号使用：

```bash
# cat /etc/passwd | awk -F ":" '{a[$3]++}END{for(i in a){if(a[i]!=1){print i, a[i]}}}'
3003 2
```

**修复方法：**

分析UID被重复使用的原因，然后删除出现问题的账号，并重新添加：

```bash
# userdel -r test
# useradd test
```
### 2.1.9 确保账号名唯一

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

要求在/etc/passwd中涉及到的账号名唯一。如果/etc/passwd中的账号名重复，则实际只有/etc/passwd文件中第一个该账号的UID有效。

通常情况下使用useradd等命令添加用户账号，不会存在账号名重复问题，但如果管理员操作失误，直接修改/etc/passwd文件，则可能导致问题。

**规则影响：**

无

**检查方法：**

使用如下命令进行检查，如果无返回输出，则表示所有账号名唯一，否则列出账号名和对应的复用次数，如test这个账号存在重复：

```bash
# cat /etc/passwd | awk -F ":" '{a[$1]++}END{for(i in a){if(a[i]!=1){print i, a[i]}}}'
test 2
```

**修复方法：**

分析账号名被重复使用的原因，然后手工删除/etc/passwd文件中出现问题的账号，并按需确定是否使用useradd命令重新添加正确的账号：

```bash
# useradd test
```
### 2.1.10 确保GID唯一

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

要求在/etc/group中涉及到的用户组GID唯一。Linux系统中根据GID来判断用户组权限，如果多个用户组使用同一个GID，则会导致这些用户组拥有一样的权限，可以相互访问拥有组权限的目录，导致越权以及信息泄露。

通常情况下使用useradd/groupadd等命令添加用户账号/用户组，不会存在GID重复问题，但如果管理员操作失误，直接修改/etc/group文件，则可能导致问题。

**规则影响：**

无

**检查方法：**

使用如下命令进行检查，如果无返回输出，则表示所有GID唯一，否则列出GID和对应的复用次数，如3003这个GID被两个用户组使用：

```bash
# cat /etc/group | awk -F ":" '{a[$3]++}END{for(i in a){if(a[i]!=1){print i, a[i]}}}'
3003 2
```

**修复方法：**

分析GID被重复使用的原因，然后删除出现问题的用户组（注意，修复时需按照实际场景，先删除属于该用户组的用户账号）：

```bash
# groupdel test1
```
### 2.1.11 确保组名唯一

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

要求在/etc/group中涉及到的用户组名唯一。如果/etc/group中的用户组名重复，则实际只有/etc/group文件中第一个该用户组的GID有效。

通常情况下使用useradd/groupadd等命令添加用户账号/用户组，不会存在用户组名重复问题，但如果管理员操作失误，直接修改/etc/group文件，则可能导致问题。

**规则影响：**

无

**检查方法：**

使用如下命令进行检查，如果无返回输出，则表示所有用户组名唯一，否则列出组名和对应的复用次数，如test这个组名存在重复：

```bash
# cat /etc/group | awk -F ":" '{a[$1]++}END{for(i in a){if(a[i]!=1){print i, a[i]}}}'
test 2
```

**修复方法：**

分析用户组名被重复使用的原因，然后手工删除/etc/group文件中出现问题的用户组，并按需确定是否使用groupadd命令重新添加正确的组名：

```bash
# groupadd test
```
### 2.1.12 应当正确设置账号有效期

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

账号应该根据自身的应用场景进行生命周期管理，例如临时创建的管理、维护账号；定期业务所需要的账号，业务生命周期结束，账号生命周期也结束了。对于这类账号，应该在生命周期结束时就直接删除，但由于管理原因，往往容易遗忘，所以建议管理员在创建账号的过程中，同时设定账号的过期时间。（注：系统账号可根据业务实际情况设置，系统账号通常用于系统服务及程序运行，不具备登录条件，不需要关注有效期。）

如果账号已经不再需要，但并没有被删除，也没有被禁用，那么由于该账号相关管理疏漏，有可能导致口令泄露或者账号被非法使用。例如原本用于日志维护的临时账号应该在1个月后过期，但到期后并没有被禁用，那么相应的管理人员在后续的时间内，依旧可以使用该账号登录系统，导致安全风险。

**规则影响：**

过期账号无法正常登陆。

**检查方法：**

检查/etc/shadow文件中除默认账号及无法登陆的账号外，所有的账号的第8个字段是否有值，这个值是从1970年1月1日开始计算的天数累加值，例如这个值如果是1，表示账号有效期到1970年1月2日24点过期。

可以通过如下命令检查，如果设置了过期时间，则直接返回该值，否则无返回数据（test为需要检查的账号）：

```bash
# cat /etc/shadow | grep "test" | awk -F ":" '{if($8!=""){print $8}}'
```

**修复方法：**

通过usermod命令设置账号的过期时间，如（test为需要被设置的账号，yyyy-mm-dd为过期时间）：

```bash
# usermod -e yyyy-mm-dd test
```
### 2.1.13 避免Home目录下存在.forward文件

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

“.forward”文件可以配置一个email地址，当用户收到邮件时，会自动转发到该地址。如无相关邮件转发场景，建议删除“.forward”文件。如果存在“.forward”文件，可能导致携带有敏感信息的用户邮件被自动转发到高风险的邮箱。

**规则影响：**

无

**检查方法：**

使用如下脚本进行检查，如果无返回输出，则表示所有Home目录下无“.forward”文件：

```bash
#!/bin/bash  
  
grep -E -v '^(halt|sync|shutdown)' "/etc/passwd" | awk -F ":" '($7 != "/bin/false" && $7 != "/sbin/nologin") {print $6}' | while read home;
do
    if [ -d "$home" ]; then
        find $home -name ".forward"
    fi
done
```

**修复方法：**

使用rm命令将检查方法找到“.forward”文件删除。
### 2.1.14 避免Home目录下存在.netrc文件

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

“.netrc”文件保存用于登录远端ftp服务器的口令，如无相关ftp场景，建议删除“.netrc”文件。“.netrc”文件中存储的口令是明文的，容易被攻击者窃取，从而导致ftp服务器敏感数据泄露，甚至服务器遭受攻击。

**规则影响：**

ftp服务器自动登录受限制

**检查方法：**

使用如下脚本进行检查，如果无返回输出，则表示所有Home目录下无“.netrc”文件：

```bash
#!/bin/bash

grep -E -v '^(halt|sync|shutdown)' "/etc/passwd" | awk -F ":" '($7 != "/bin/false" && $7 != "/sbin/nologin") {print $6}' | while read home;
do
    if [ -d "$home" ]; then
        find $home -name ".netrc"
    fi
done
```

**修复方法：**

使用rm命令将检查方法找到“.netrc”文件删除。
## 2.2 口令
### 2.2.1 确保口令复杂度设置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

口令设置过于简单，容易被猜测，太短的口令、纯数字或纯字母的口令容易被暴力破解工具猜测出来。在系统设置口令时，应强制用户使用复杂口令。对于高安全要求的业务场景，可参考业界最佳实践，比如：口令长度设置为14位或更长，对于四种字符组合，建议每种字符至少出现一次，保证口令不会被轻易破解。

openEuler要求设置口令复杂度如下：

- 口令长度至少8个字符。
- 口令必须包含如下至少3种字符的组合：
  - 至少一个小写字母。
  - 至少一个大写字母。
  - 至少一个数字。
  - 至少一个特殊字符：`~!@#$%^&*()-_=+|[{}];:'",<.>/?和空格。

考虑到在不同场景下的易用性，openEuler默认不配置enforce_for_root和retry值，请根据实际场景按需配置。

**规则影响：**

口令规则太过复杂，又会影响系统的易用性，给用户的正常使用造成不便。所以可以根据实际需求和使用场景，设计符合安全要求的口令复杂度。

**检查方法：**

方法1：
- /etc/pam.d/system-auth和/etc/pam.d/password-auth分别提供该功能项的配置，不同应用程序或者服务对应的配置项，需根据各自include的配置文件而定：

  ```bash
  # grep system-auth /etc/pam.d/ -r
  /etc/pam.d/login:auth       substack     system-auth
  /etc/pam.d/login:account    include      system-auth
  /etc/pam.d/login:password   include      system-auth
  /etc/pam.d/login:session    include      system-auth
  /etc/pam.d/sudo:auth       include      system-auth
  /etc/pam.d/sudo:account    include      system-auth
  /etc/pam.d/sudo:password   include      system-auth
  /etc/pam.d/sudo:session    include      system-auth-su
  ```

  以上只列举部分显示结果，从以上结果可知，login和sudo的账号认证采用/etc/pam.d/system-auth文件中的配置。

  后续以/etc/pam.d/system-auth为例进行说明。

- 在/etc/pam.d/system-auth文件中检查“设置口令复杂度”的配置情况：

  ```bash
  # grep pam_pwquality /etc/pam.d/system-auth
  password    requisite     pam_pwquality.so minlen=8 minclass=3 enforce_for_root try_first_pass local_users_only retry=3 dcredit=0 ucredit=0 lcredit=0 ocredit=0
  ```

方法2：
- 在/etc/security/pwquality.conf文件中检查“设置口令复杂度”的配置情况：

  ```bash
  #cat /etc/security/pwquality.conf
  minlen=8
  minclass=3
  retry=3
  dcredit=0
  ucredit=0
  lcredit=0
  ocredit=0
  enforce_for_root
  ```
  此处仅列举本规范关注的配置项。

**修复方法：**

方法1：
- 口令复杂度的设置可以通过修改/etc/pam.d/password-auth和/etc/pam.d/system-auth文件实现。以/etc/pam.d/system-auth文件为例，具体配置字段如下：
  ```bash
  # vim /etc/pam.d/system-auth
  password    requisite     pam_pwquality.so minlen=8 minclass=3 enforce_for_root try_first_pass local_users_only retry=3 dcredit=0 ucredit=0 lcredit=0 ocredit=0
  ```

方法2：
- 在/etc/security/pwquality.conf文件中配置如下字段：
  ```bash
  # vim /etc/security/pwquality.conf
  minlen=8
  minclass=3
  retry=3
  dcredit=0
  ucredit=0
  lcredit=0
  ocredit=0
  enforce_for_root
  ```

pam_pwquality.so配置项参数字段说明如下表：

| **配置项**       | **说明**                                                     |
| ---------------- | ------------------------------------------------------------ |
| minlen=8         | 口令长度至少包含8个字符。 说明： 建议配置更长的口令最小长度。 |
| minclass=3       | 口令至少包含大写字母、小写字母、数字和特殊字符中的任意3种    |
| ucredit=0        | 口令包含任意个大写字母                                       |
| lcredit=0        | 口令包含任意个小写字母                                       |
| dcredit=0        | 口令包含任意个数字                                           |
| ocredit=0        | 口令包含任意个特殊字符                                       |
| retry=3          | 每次修改最多可以尝试3次                                      |
| enforce_for_root | 本设置对root账号同样有效                                     |
### 2.2.2 禁止使用历史口令

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

频繁使用相同的历史口令容易造成口令泄露而被攻击者攻击。为了用户账号的安全，需要配置“禁用历史口令”功能。根据业务实际场景，合理的设置禁用历史口令次数，但不得小于5次。

考虑到社区版本在不同场景下的易用性，openEuler发行版默认不配置禁用历史口令，请根据实际场景按需配置。

**规则影响：**

禁止历史口令次数设置过大，易增加口令管理成本。

**检查方法：**

/etc/pam.d/system-auth和/etc/pam.d/password-auth都各自提供该功能项的配置，不同应用程序或者服务对应的配置项，需根据各自include的配置文件而定。

- 在/etc/pam.d/system-auth文件中检查“禁用历史口令”的配置情况，检查配置remember值是否不小于5：

  ```bash
  # grep pam_pwhistory /etc/pam.d/system-auth
  password    required      pam_pwhistory.so use_authtok remember=5 enforce_for_root
  ```

- 在/etc/pam.d/password-auth文件中检查“禁用历史口令”的配置情况，检查配置remember值是否不小于5：

  ```bash
  # grep pam_pwhistory /etc/pam.d/password-auth
  password    required      pam_pwhistory.so use_authtok remember=5 enforce_for_root
  ```

**修复方法：**

“禁用历史口令”的设置可以通过修改/etc/pam.d/password-auth和/etc/pam.d/system-auth文件实现。

- 在/etc/pam.d/system-auth文件配置如下字段：

  ```bash
  # vim /etc/pam.d/system-auth
  password    required      pam_pwhistory.so use_authtok remember=5 enforce_for_root
  ```

- 在/etc/pam.d/password-auth文件配置如下字段：

  ```bash
  # vim /etc/pam.d/password-auth
  password    required      pam_pwhistory.so use_authtok remember=5 enforce_for_root
  ```

pam_pwhistory.so配置项参数字段说明如下表：

| **配置项**       | **说明**                            |
| ---------------- | ----------------------------------- |
| remember=5       | 口令不能修改为过去5次使用过的旧口令 |
| enforce_for_root | 本设置对root账号同样有效            |

### 2.2.3 确保用户修改自身口令时需验证旧口令

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

为了防止第三方恶意修改其他账户口令，用户修改自身口令时需验证旧口令。

按照业界通用做法，root账号修改自身口令时不需要验证旧口令。root账号可以直接修改/etc/passwd和/etc/shadow文件，在修改自身口令时验证旧口令无实质的安全提升，所以遵循业界通常做法，root账号在修改口令时，无需验证旧口令。而普通账号需要验证通过旧口令后，才能进行新口令的设置，否则会引发安全风险，例如：普通账号的所有者在登录系统后未锁定屏幕，而直接离开座位，附近的攻击者可以在终端上修改该普通账号的口令。

该规则为pam_unix模块默认支持，无需额外配置。

**规则影响：**

普通用户如果忘记旧口令，则无法自行修改口令，降低易用性。

**检查方法：**

- root账号更改口令情况如下：

  ```bash
  # passwd
  Changing password for user root.
  New password:
  Retype new password:
  passwd: all authentication tokens updated successfully.
  ```

- 普通账号（如test）更改口令：

  ```bash
  $ passwd
  Changing password for user test.
  Changing password for test.
  Current password:
  New password:
  Retype new password:
  passwd: all authentication tokens updated successfully.
  ```

**修复方法：**

该规则为pam_unix模块默认支持，无需配置。

### 2.2.4 确保口令中不包含账号字符串

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

为了用户账号的安全，要求配置“口令中不包含账号字符串”功能。

口令跟账号名字符相同，或者是账号名字符逆序容易被攻击者猜测，而且口令中包含账号名字符，也增加了口令被破译的风险。账号名小于等于3个字符的情况下不作要求，但建议实际场景中设置长度合理的账号名。

账号名大于3个字符时，其口令不能是如下字符：

- 账号名称
- 账号名称逆序
- 包含账号名称字符

**规则影响：**

无法设置包含账号字符串的口令。

**检查方法：**

- /etc/pam.d/system-auth和/etc/pam.d/password-auth分别提供该功能项的配置，不同应用程序或者服务对应的配置项，需根据各自include的配置文件而定：

  ```bash
  # grep system-auth /etc/pam.d/ -r
  /etc/pam.d/login:auth       substack     system-auth
  /etc/pam.d/login:account    include      system-auth
  /etc/pam.d/login:password   include      system-auth
  /etc/pam.d/login:session    include      system-auth
  /etc/pam.d/sudo:auth       include      system-auth
  /etc/pam.d/sudo:account    include      system-auth
  /etc/pam.d/sudo:password   include      system-auth
  /etc/pam.d/sudo:session    include      system-auth-su
  ```

  以上只列举部分显示结果，从以上结果可知，login和sudo的账号认证采用/etc/pam.d/system-auth文件中的配置。

  后续以/etc/pam.d/system-auth为例进行说明。

- 在/etc/pam.d/system-auth文件中检查“口令中不包含账号字符串”的配置情况，不应包含“usercheck=0”字段：

  ```bash
  # grep pam_pwquality /etc/pam.d/system-auth
  password    requisite     pam_pwquality.so minlen=8 minclass=3 enforce_for_root try_first_pass local_users_only retry=3 dcredit=0 ucredit=0 lcredit=0 ocredit=0
  ```

**修复方法：**

pam_pwquality.so是一个执行口令质量检测的pam模块，默认支持“口令中不包含账号字符串”该功能。所以，配置文件中包含该模块，且未配置“usercheck=0”，即可实现对应的功能；反之，则无法实现。

通过修改/etc/pam.d/password-auth和/etc/pam.d/system-auth文件实现。以/etc/pam.d/system-auth文件为例，如果配置中存在“usercheck=0”字段，则删除，具体配置字段如下：

```bash
# vim /etc/pam.d/system-auth
password    requisite     pam_pwquality.so minlen=8 minclass=3 enforce_for_root try_first_pass local_users_only retry=3 dcredit=0 ucredit=0 lcredit=0 ocredit=0
```
### 2.2.5 确保口令使用强Hash算法加密

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

出于系统安全考虑，口令不允许明文存储在系统中，应该加密保护。在不需要还原口令的场景，必须使用不可逆算法加密。如果加密算法强度过低，攻击者可以通过加大算力，在口令被更新前，强行计算出相同hash结果的原始字符串，无论该字符串是否同原口令一致，均可用以登录对应账号。目前业界已知的MD5、sha1等弱算法，均可在有限算力情况下碰撞出相同密文的两段不同原文。对用户账号的口令使用强hash算法进行加密，能有效加大口令被碰撞破解的难度，从而降低口令泄漏的风险。可根据实际需求，进行口令加密算法配置，但是配置的算法强度不得低于sha512。

openEuler目前口令加密默认采用sha512算法，已满足安全要求。

**规则影响：**

无

**检查方法：**

- /etc/pam.d/system-auth和/etc/pam.d/password-auth分别提供该功能项的配置，不同应用程序或者服务对应的配置项，需根据各自include的配置文件而定：

  ```bash
  # grep system-auth /etc/pam.d/ -r
  /etc/pam.d/login:auth       substack     system-auth
  /etc/pam.d/login:account    include      system-auth
  /etc/pam.d/login:password   include      system-auth
  /etc/pam.d/login:session    include      system-auth
  /etc/pam.d/sudo:auth       include      system-auth
  /etc/pam.d/sudo:account    include      system-auth
  /etc/pam.d/sudo:password   include      system-auth
  /etc/pam.d/sudo:session    include      system-auth-su
  ```

  以上只列举部分显示结果，从以上结果可知，login和sudo的账号认证采用/etc/pam.d/system-auth文件中的配置。

  后续以/etc/pam.d/system-auth为例进行说明。

- 在/etc/pam.d/system-auth文件中检查“口令使用强Hash算法加密”的配置情况：

  ```bash
  # grep sha512 /etc/pam.d/system-auth
  password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
  ```

**修复方法：**

“口令使用强Hash算法加密”的设置可以通过修改/etc/pam.d/password-auth和/etc/pam.d/system-auth文件实现。

以/etc/pam.d/system-auth文件为例，具体配置字段如下：

```bash
# vim /etc/pam.d/system-auth
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
```
### 2.2.6 确保弱口令字典设置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

若用户口令是弱口令，就很容易被攻击者猜测到、或者在较短时间内通过字典攻击法进行破解。弱口令字典是一个包含强度不够、容易被猜测到的口令的集合。弱口令包括：系统默认的口令、过去曾被泄露的口令等。OS提供口令字典检查功能，在创建、修改口令的时候检查，如果命中则禁止使用该口令。弱口令字典可更新、可扩展。可根据实际业务场景，设定适合本业务的弱口令字典。

在升级场景中需要注意：历史版本是否启用了弱口令字典检查，或者新版本是否新增了弱口令清单。

**规则影响：**

原系统中可以使用的口令在新版本中可能被认定为弱口令，导致口令无法设置成功。

**检查方法：**

方法1：
- /etc/pam.d/system-auth和/etc/pam.d/password-auth分别提供该功能项的配置，不同应用程序或者服务对应的配置项，需根据各自include的配置文件而定：

  ```bash
  # grep system-auth /etc/pam.d/ -r
  /etc/pam.d/login:auth       substack     system-auth
  /etc/pam.d/login:account    include      system-auth
  /etc/pam.d/login:password   include      system-auth
  /etc/pam.d/login:session    include      system-auth
  /etc/pam.d/sudo:auth       include      system-auth
  /etc/pam.d/sudo:account    include      system-auth
  /etc/pam.d/sudo:password   include      system-auth
  /etc/pam.d/sudo:session    include      system-auth-su
  ```

  以上只列举部分显示结果，从以上结果可知，login和sudo的账号认证采用/etc/pam.d/system-auth文件中的配置。

  后续以/etc/pam.d/system-auth为例进行说明。

- 在/etc/pam.d/system-auth文件中检查“设置弱口令字典”的配置情况：

  ```bash
  # grep pam_pwquality /etc/pam.d/system-auth
  password    requisite     pam_pwquality.so minlen=8 minclass=3 enforce_for_root try_first_pass local_users_only retry=3 dcredit=0 ucredit=0 lcredit=0 ocredit=0
  ```
  如果没有配置dictcheck=0，则默认为开启，无需手动配置。
- 使用如下命令，导出字典库到文件dictionary.txt中：

  ```bash
  # cracklib-unpacker /usr/share/cracklib/pw_dict > dictionary.txt
  ```

方法2：
- 在/etc/security/pwquality.conf文件中检查“弱口令字典”的配置情况：

  ```bash
  # grep -rnR "dictcheck" /etc/security/pwquality.conf
  ```
  如果没有配置dictcheck=0，则默认开启，无需手动配置。

**修复方法：**

pam_pwquality.so是一个执行口令质量检测的pam模块，默认支持“设置弱口令字典”功能，使用如下操作可以更新弱口令字典库：

- 使用如下命令，导出字典库到文件dictionary.txt中：

  ```bash
  # cracklib-unpacker /usr/share/cracklib/pw_dict > dictionary.txt
  ```

- 将弱口令字典导出并修改后，可执行如下命令进行字典库更新：

  ```bash
  # create-cracklib-dict dictionary.txt
  ```

- 可在原字典库基础上新增其他字典内容，如custom.txt：

  ```bash
  # create-cracklib-dict dictionary.txt custom.txt
  ```
### 2.2.7 确保口令有效期设置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

如果口令长期不修改，则通过暴力破解等方法，容易增加口令被破解的可能性，从而影响系统安全；但该值如果设置过小，则导致口令频繁修改，增加管理成本，且容易导致用户因长时间未登录而无法再次登录，所以在设置该值时需要根据实际业务场景进行判断。

口令需要设置有效期，口令过期后用户重新登录时，提示口令过期，并强制修改，否则无法进入系统。口令最大有效期应为90天或者更短；口令过期前7天或更长时间应开始提示用户修改口令；两次修改口令的最小间隔时间建议设置为7天，可根据业务场景调整。

由于root是最高权限账号，如果长期未登录，导致root口令过期，或者因为频繁修改导致遗忘，系统将无法登录，存在管理风险。建议根据实际业务场景决定是否设置root口令过期时间，对于需要频繁登录root账号的场景，建议设置较短的过期时间；对于日常管理使用非root账号的，建议设置相对较长的过期时间。

考虑到社区版本在不同场景下的易用性，openEuler发行版默认不配置口令有效期和两次修改口令的最小间隔时间，请根据实际场景按需配置。

**规则影响：**

PASS_MAX_DAYS（口令有效期）：设置过长，会降低安全性，增加被暴力破解的概率，设置过短，会增加口令的管理复杂度；

PASS_WARN_AGE（口令过期前提醒）：设置过长，会过早提醒，降低用户体验，设置过短，会导致用户错过修改口令时间；

PASS_MIN_DAYS（两次修改口令的最小间隔时间）：设置过短，用户可以频繁更改口令以规避历史口令防重用检查机制；

**检查方法：**

- 检查/etc/login.defs文件中是否已经配置相关字段：

  ```bash
  # grep ^PASS_MAX_DAYS /etc/login.defs 
  PASS_MAX_DAYS 90
  # grep ^PASS_WARN_AGE /etc/login.defs 
  PASS_WARN_AGE 7
  # grep ^PASS_MIN_DAYS /etc/login.defs
  PASS_MIN_DAYS 0
  ```

- 检查/etc/shadow文件中指定账号的配置是否正确：

  ```bash
  # grep ^test: /etc/shadow 
  test:!:18599:0:90:7:35::  
  ```

**修复方法：**

有两种设置方法：

- 修改/etc/login.defs文件中的默认配置，对后续新建账号口令默认生效：

  ```bash
  # vim /etc/login.defs
  PASS_MAX_DAYS 90
  PASS_MIN_DAYS 0
  PASS_WARN_AGE 7
  ```

- 修改shadow文件中具体某个账号的口令有效期，新增的账号，口令的默认有效期同/etc/login.defs文件中定义一致，对应的值会写到shadow文件中，例如：

  ```bash
  # useradd test
  # cat /etc/shadow | grep test
  test:!:18599:0:90:7:35::
  ```

  shadow文件中每一行记录一个账号的口令信息，通过冒号“:”划分为9个字段，如上举例中：

  - 第4字段表示两次修改口令的最小间隔时间，默认为0，表示不作限制；
  - 第5字段表示口令最大有效期（自设置之日起），默认90天，设置成99999表示永不过期；
  - 第6字段表示口令过期前几天开始提醒，默认7天；
  - 第7个字段表示口令修改有效期，过期后几天内允许用户修改。时间段内，用户登录时强制要求修改口令；超过这个时间，直接拒绝用户登录，默认值是35天。

  管理员可通过passwd命令进行修改。

  设置两次口令修改最小间隔时间：

  ```bash
  # passwd -n 0 test
  Adjusting aging data for user test.
  passwd: Success
  ```

  设置口令最大有效期：

  ```bash
  # passwd -x 90 test
  Adjusting aging data for user test.
  passwd: Success
  ```

  设置口令过期前提醒时间：

  ```bash
  # passwd -w 7 test
  Adjusting aging data for user test.
  passwd: Success
  ```

  设置口令修改有效期（无法通过/etc/login.defs设置默认值）：

  ```bash
  # passwd -i 35 test
  Adjusting aging data for user test.
  passwd: Success 
  ```
### 2.2.8 禁止空口令登录

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

空口令登录是指在用户账号登录时，不输入口令的情况下也能成功登录系统。

若允许空口令登录，会增加空口令账号本身被攻击或被用来作为攻击账号的风险。

**规则影响：**

无

**检查方法：**

检查/etc/ssh/sshd_config中是否配置了禁止空口令登录的字段：

```bash
# grep ^PermitEmptyPasswords /etc/ssh/sshd_config | grep no
PermitEmptyPasswords no
```

**修复方法：**

在/etc/ssh/sshd_config中配置禁止空口令登录，并重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
PermitEmptyPasswords no
# systemctl restart sshd
```
### 2.2.9 确保Grub已设置口令保护

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

Grub是Linux的默认引导程序，通过引导程序可以设置系统的启动模式，而设置Grub口令可以防御攻击者通过修改Grub设置进入单用户模式。

如果没有设置Grub口令，攻击者可以轻易进入Grub编辑菜单，通过修改启动参数进行攻击行为，例如：进入单用户模式修改root口令，窃取数据。

UEFI和legacy是两种不同的引导方式，对应的Grub配置文件路径会存在差异。UEFI的配置路径为：/boot/efi/EFI/openEuler，legecy的配置路径为/boot/grub2。

**规则影响：**

需要验证Grub口令后才能进入Grub编辑菜单。

**检查方法：**

UEFI模式下：

方法1：

- 查看grub.cfg配置文件是否存在password_pbkdf2相关配置：

  ```bash
  # grep password_pbkdf2 /boot/efi/EFI/openEuler/grub.cfg
  password_pbkdf2 root ${GRUB2_PASSWORD}
  ```

- GRUB2_PASSWORD是定义在user.cfg文件中的口令密文，“xxxx”表示密文内容：

  ```bash
  # cat /boot/efi/EFI/openEuler/user.cfg
  GRUB2_PASSWORD=grub.pbkdf2.sha512.10000.xxxx
  ```

方法2：

- 查看grub.cfg配置文件是否存在password_pbkdf2相关配置：

  ```bash
  # grep grub.pbkdf2.sha512.10000 /boot/efi/EFI/openEuler/grub.cfg
  grub.pbkdf2.sha512.10000.xxxx
  ```

legecy模式下：

方法1：

- 查看grub.cfg配置文件是否存在password_pbkdf2相关配置：

  ```bash
  # grep password_pbkdf2 /boot/grub2/grub.cfg
  password_pbkdf2 root ${GRUB2_PASSWORD}
  ```

- GRUB2_PASSWORD是定义在user.cfg文件中的口令密文，“xxxx”表示密文内容：

  ```bash
  # cat /boot/grub2/user.cfg
  GRUB2_PASSWORD=grub.pbkdf2.sha512.10000.xxxx
  ```

方法2：

- 查看grub.cfg配置文件是否存在password_pbkdf2相关配置：

  ```bash
  # grep grub.pbkdf2.sha512.10000 /boot/grub2/grub.cfg
  grub.pbkdf2.sha512.10000.xxxx
  ```

**修复方法：**

- openEuler在安装阶段通过人工方式在图形界面设置Grub2口令。

- 建议用户首次登录时修改口令并定期更新，避免口令泄露后，启动选项被篡改，导致系统启动异常。

  在终端输入grub2-mkpasswd-pbkdf2后，根据提示输入明文口令后，生成sha512加密的口令密文，“xxxx”表示密文内容：

  ```bash
  # grub2-mkpasswd-pbkdf2
  Enter password: 
  Reenter password: 
  PBKDF2 hash of your password is 
  grub.pbkdf2.sha512.10000.xxxx
  ```

  UEFI模式下，将新口令密文输出到/boot/efi/EFI/openEuler/user.cfg文件中：

  ```bash
  # echo "GRUB2_PASSWORD=grub.pbkdf2.sha512.10000.xxxx" > /boot/efi/EFI/openEuler/user.cfg
  ```

  legecy模式下，将新口令密文输出到/boot/grub2/user.cfg文件中：

  ```bash
  # echo "GRUB2_PASSWORD=grub.pbkdf2.sha512.10000.xxxx" > /boot/grub2/user.cfg
  ```

- 系统下次重启时，如果需要进入Grub2菜单，将需要验证新口令。
### 2.2.10 确保单用户模式已设置口令保护

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

编辑grub启动菜单，在linux启动命令行添加“s”或“single”命令，可以进入单用户模式，单用户模式属于紧急救援模式，可以对系统进行修改。例如修改root口令，所以要求在进入单用户模式时，验证root口令。

openEuler系统默认已经加固，进入单用户模式必须输入root口令。

**规则影响：**

如果管理员忘记root口令，将无法通过单用户模式进入系统修改。

**检查方法：**

通过grep命令检查rescue和emergency服务中是否使用systemd-sulogin-shell登录：

```bash
# grep /systemd-sulogin-shell /usr/lib/systemd/system/rescue.service
# grep /systemd-sulogin-shell /usr/lib/systemd/system/emergency.service
```

**修复方法：**

- 在/usr/lib/systemd/system/rescue.service文件中，修改ExecStart项为：

  ```bash
  # vim /usr/lib/systemd/system/rescue.service
  ExecStart=-/usr/lib/systemd/systemd-sulogin-shell rescue
  ```

- 在/usr/lib/systemd/system/emergency.service文件中，修改ExecStart项为：

  ```bash
  # vim /usr/lib/systemd/system/emergency.service
  ExecStart=-/usr/lib/systemd/systemd-sulogin-shell emergency
  ```

### 2.2.11 确保账号在首次登录时强制修改口令

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

对于非用户本人设置的口令，如管理员重置的口令，如果在业务环境上没有被及时修改，极易引起低成本的攻击事件，所以要求用户在首次登录账号时强制修改口令。
root口令除外。

**规则影响：**

无

**检查方法：**

检查/etc/shadow文件中指定账号的配置是否正确：

```bash
# grep ^test: /etc/shadow 
test:!:0:0:90:7:35::
```

此处，以冒号“:”分割的第3个字段，如果是0，表示此账号对应口令已被强制设置为过期。

**修复方法：**

管理员在重置账号口令后，通过如下命令可以将该口令立即过期，该账号下次登录时会被要求强制口令修改，此种方式过期的口令不受口令修改有效期（默认35天）的约束（test为举例的账号）：

```bash
# passwd -e test
```
## 2.3 身份认证
### 2.3.1 确保登录失败一定次数后锁定账号

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

用户使用账号登录系统，如果连续登录失败一定次数后，系统会锁定该账号登录，即一定时间内不允许该账号继续登录，防止恶意的破解系统口令。账号锁定期间，任何输入被判定为无效，锁定时间不因用户的再次输入而重新计时；解锁后，错误输入记录被清空。通过上述设置可以有效防范口令暴力破解，增强系统的安全性。系统默认设定的连续登录失败次数为3次；登录失败后，默认锁定的时间为300s。

考虑到社区版本在不同场景下的易用性，openEuler发行版默认不提供该项安全功能，用户应根据实际应用场景和需求，对默认的失败次数和锁定时间进行配置。

**规则影响：**

失败次数数值设置过小和锁定时间的数值设置过大，会影响使用体验。

**检查方法：**

- /etc/pam.d/system-auth和/etc/pam.d/password-auth分别提供该功能项的配置，不同应用程序或者服务对应的配置项，需根据各自include的配置文件而定：

  ```bash
  # grep system-auth /etc/pam.d/ -r
  /etc/pam.d/login:auth       substack     system-auth
  /etc/pam.d/login:account    include      system-auth
  /etc/pam.d/login:password   include      system-auth
  /etc/pam.d/login:session    include      system-auth
  /etc/pam.d/sudo:auth       include      system-auth
  /etc/pam.d/sudo:account    include      system-auth
  /etc/pam.d/sudo:password   include      system-auth
  /etc/pam.d/sudo:session    include      system-auth-su
  ```

  以上只列举部分显示结果，从以上结果可知，login和sudo的账号认证采用/etc/pam.d/system-auth文件中的配置。

  后续以/etc/pam.d/system-auth为例进行说明。

- 在/etc/pam.d/system-auth文件中检查“连续失败登录次数”的配置情况：

  ```bash
  # grep deny /etc/pam.d/system-auth
  auth  required  pam_faillock.so preauth audit deny=3 even_deny_root unlock_time=300
  auth  [default=die] pam_faillock.so authfail audit deny=3 even_deny_root unlock_time=300
  auth  sufficient  pam_faillock.so authsucc audit deny=3 even_deny_root unlock_time=300
  auth      required   pam_deny.so
  password  required   pam_deny.so
  ```

- 在/etc/pam.d/system-auth文件中检查“锁定时间”的配置情况：

  ```bash
  # grep unlock_time /etc/pam.d/system-auth
  auth  required  pam_faillock.so preauth audit deny=3 even_deny_root unlock_time=300
  auth  [default=die] pam_faillock.so authfail audit deny=3 even_deny_root unlock_time=300
  auth  sufficient  pam_faillock.so authsucc audit deny=3 even_deny_root unlock_time=300
  ```

**修复方法：**

可以通过修改/etc/pam.d/password-auth和/etc/pam.d/system-auth中所有“deny=”和“unlock_time=”字段后的数，来分别完成对“连续失败登录次数”和“锁定时间”的配置。以/etc/pam.d/system-auth文件为例，具体配置字段如下：

```bash
# vim /etc/pam.d/system-auth
auth  required  pam_faillock.so preauth audit deny=3 even_deny_root unlock_time=300
auth  [default=die] pam_faillock.so authfail audit deny=3 even_deny_root unlock_time=300
auth  sufficient  pam_faillock.so authsucc audit deny=3 even_deny_root unlock_time=300
```
### 2.3.2 确保会话超时时间设置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

设置合理的会话超时时间可以降低因管理员人为原因而导致系统被攻击者攻击的风险。

考虑到社区版本在不同场景下的易用性，openEuler发行版默认不配置会话超时时间，请根据实际场景按需配置。

**规则影响：**

会话超时时间设置过长，甚至永不超时，当管理员离开时没有退出登录，其他人员就可以直接在终端上以管理员权限进行操作。
如果设置过短，则频繁锁定，增加管理员输入口令次数，降低用户体验的同时，也容易引入安全风险，管理员周边人员有较多的机会可以窥探到输入的口令。

**检查方法：**

```bash
# grep "^export TMOUT" /etc/profile
export TMOUT=300
```

**修复方法：**

- 修改/etc/profile文件TMOUT字段，根据业务场景修改为合理的值：

  ```bash
  # vim /etc/profile
  export TMOUT=<seconds>
  ```

- 使用source命令使之生效：

  ```bash
  # source /etc/profile    
  ```

### 2.3.3 确保Warning Banners包含合理的信息

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

Warning Banners包含有系统登录界面添加的警告信息，为所有登录系统的用户标识出本系统的安全警告，安全警告可以根据业务场景包括系统所属的组织，登录行为所受到的监视或者记录，非授权登录或者入侵会受到的法律制裁等内容。不合适的安全警告信息，可能增加系统被攻击的风险，或触犯当地法律法规。

Warning Banners不应将系统版本、应用服务器类型、功能等暴露给用户，避免攻击者获取到系统信息，实施攻击。除此之外，还需要正确配置文件所有权，否则未经授权的用户可能会使用不正确或误导性信息来修改文件。

**规则影响：**

无

**检查方法：**

* 通过cat命令，查看/etc/motd、/etc/issue、/etc/issue.net三个文件中警告信息是否合理，是否存在系统版本、应用服务器类型、功能等信息；

* 通过ll命令查看/etc/motd、/etc/issue、/etc/issue.net三个文件权限是否为644；

**修复方法：**

* 通过vim命令，修改/etc/motd、/etc/issue、/etc/issue.net三个文件中的告警信息；

* 通过chmod命令修改/etc/motd、/etc/issue、/etc/issue.net三个文件的权限为644；
### 2.3.4 应当正确配置Banner路径

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

Banner路径指向一个文件，文件中包含有用户登录SSH前在客户端给出的提示信息，用户可根据实际业务场景配置该文件中的内容。

如果不配置，则默认没有显示。

**规则影响：**

无

**检查方法：**

使用grep命令查看配置，如果返回为空，表示未配置：

```bash
# grep -i "^Banner" /etc/ssh/sshd_config
Banner /etc/issue.net
```

**修复方法：**

* 修改/etc/ssh/sshd_config文件，配置Banner字段指向的文件，重启sshd服务：

  ```bash
  # vim /etc/ssh/sshd_config
  Banner /etc/issue.net
  # systemctl restart sshd
  ```

* 修改Banner指向文件中的内容：

  ```bash
  # vim /etc/issue.net
  Authorized users only. All activities may be monitored and reported.
  ```
## 2.4 访问控制
### 2.4.1 限制历史命令记录数量

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

HISTSIZE是一个环境变量，用于控制命令历史记录的大小。具体来说，HISTSIZE定义了命令历史记录中可以存储的命令条目数量。通过设置HISTSIZE的值，可以限制或增加命令历史记录的大小，从而控制在命令行终端中可用的以前输入的命令数量。

例如，设置HISTSIZE=100将限制命令历史记录最多存储100条命令。一旦命令历史记录达到这个限制，新的命令将会覆盖最旧的命令，以保持历史记录的大小不超过指定的值。

作用：较小的历史记录可以减少敏感信息（如密码）在历史记录中被保留的风险。

建议系统限制查看历史命令的数量，建议50或100

**规则影响：**

限制的值设置过小，会导致历史使用的命令不可见，易用性下降。

**检查方法：**

1. 查看环境变量 HISTSIZE 设置的值：

  ```bash
  # echo $HISTSIZE
  100
  ```

2. 查看 profile 文件 HISTSIZE 设置的值：

  ```bash
  # grep -iP "^HISTSIZE" /etc/profile
  HISTSIZE=100
  ```
如果检测1中输出为1-100范围，且检测2中"HISTSIZE="等于号之后输出的值为1-100的范围，说明通过检查，否则检测未通过。

**修复方法：**

查看profile文件中环境变量HISTSIZE的值，运行以下命令设置历史命令记录数量为1-100范围内的值并生效即可：

```bash
# grep -qiP "^HISTSIZE" /etc/profile && sed -i "/^HISTSIZE/cHISTSIZE=100" /etc/profile || echo -e "HISTSIZE=100" >> /etc/profile
# source /etc/profile
```
### 2.4.2 应当启用enforce模式

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

SELinux是Linux发行版中内置的安全模块，通过细粒度的访问控制机制，实现应用程序对资源的访问控制，从而提高系统的安全性。SELinux的运行模式有三种：

* enforcing（强制模式）：当访问无权限时，阻止资源访问，并记录audit日志；

* permissive（宽容模式）：当访问无权限时，仅记录audit日志，不阻止资源访问；

* disable（禁用模式）：关闭SELinux功能；

SELinux只有工作在enforcing模式时才能有效启用并保护系统，若工作在其它模式，则无法对系统提供保护，而系统中的进程会默认有较大的权限（尤其是以root身份运行的进程），可能会给系统带来安全风险。

**规则影响：**

系统开启enforce模式会拒绝部分高风险操作（依赖于策略配置），易用性降低。

**检查方法：**

输入命令查看当前系统SELinux运行模式是否为enforcing：

```bash
# getenforce
Enforcing
```

使用如下命令查看系统默认SELinux运行模式是否为enforcing：

```bash
# grep "^SELINUX=" /etc/selinux/config
SELINUX=enforcing
```

**修复方法：**

使用setenforce命令设置当前系统SELinux的运行模式：

```bash
# setenforce 1
# getenforce
Enforcing
```

设置/etc/selinux/config文件中的SELINUX参数，重启操作系统后生效：

```bash
SELINUX=enforcing
```
### 2.4.3 应当正确配置SELinux策略

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

SELinux的策略分为两种，系统基础策略和自定义策略：

基础策略：定义在基础策略包中的策略，包括selinux-policy、selinux-policy-targeted、selinux-policy-mls等。

自定义策略：用户修改或添加的策略。

SELinux可以实现进程级别的强制访问控制，通过根据最小权限原则配置合理的策略，限制系统中关键应用和关键资源的行为，可以提高系统的安全性。

如果未对应用程序配置合理的策略，可能产生两种影响：

* 如果未对应用程序配置策略，应用程序有可能运行在unconfined_t或其他权限较大的域，若被攻击可能对系统或业务造成较大影响；

* 如果为应用程序配置了不合理的策略，有可能影响应用程序的正常运行。

**规则影响：**

无

**检查方法：**

运行以下命令查看当前系统策略，建议配置为targeted：

```bash
# sestatus | grep 'Loaded policy name'
Loaded policy name:             targeted
```

运行以下命令，输出为空，表示无异常规则和异常访问行为，若不为空，需要分析被禁止的访问行为是否为正常访问行为，如果为正常访问行为，则需要修改策略：

```bash
# grep avc /var/log/audit/audit.log*
```

**修复方法：**

设置基础策略包为targeted策略包：

* 安装目标基础策略包：

  ```bash
  # yum install selinux-policy-targeted
  ```

* 设置/etc/selinux/config文件中的SELINUXTYPE参数以修改系统基础策略包：

  ```bash
  # SELINUXTYPE=targeted
  ```

*  在根目录下创建.autorelabel文件，用于系统重启后刷新文件标签：

  ```bash
  # touch /.autorelabel
  ```

* 重启操作系统。

若应用程序运行异常，需要为应用程序配置合理的SELinux策略。
### 2.4.4 确保su受限使用

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

su命令可以使一个普通用户拥有超级用户或其他用户的权限，它经常被用于从普通用户账号切换到系统root账号。su命令为用户变更身份提供了便捷的途径，但如果不加约束的使用su命令，会给系统带来潜在的风险。通过对用户使用su访问root账号的权限进行限制，仅对部分账号进行su使用授权，可以提高系统账号使用的安全性。

openEuler默认仅允许wheel组中的普通用户具有su的使用权限。

**规则影响：**

非wheel组用户无法使用su

**检查方法：**

检查/etc/pam.d/su中是否配置了非wheel组用户账号禁止使用su：

```bash
# grep pam_wheel.so /etc/pam.d/su | grep required
auth	 required	 pam_wheel.so use_uid
```

**修复方法：**

修改/etc/pam.d/su配置文件，配置非wheel组用户账号禁止使用su：

```bash
# vim /etc/pam.d/su
auth	 required	 pam_wheel.so use_uid
```
### 2.4.5 确保普通用户通过sudo运行特权程序

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

sudo可以使设定的普通用户以root权限执行某些特定的程序。大部分系统管理命令都需要使用root权限执行，对于系统管理员来说，适当地对其他用户授权可以减轻系统管理员负担，但直接授予普通用户root口令会带来安全风险，使用sudo则可以规避这一问题。系统中需要以root账号运行的特权程序，可以使用sudo机制避免使用root账号登录。 

使用sudo代替root用户运行特权程序不仅可以减轻系统管理员负担，同时由于使用sudo时无需输入root口令，这提高了安全性。

**规则影响：**

无

**检查方法：**

检查/etc/sudoers中是否配置了普通用户执行sudo：

```bash
# grep "(root)" /etc/sudoers
test_sudo  ALL=(root)  /bin/ping
```

说明：示例中“/bin/ping”为可以使用sudo执行的程序。实际上，具体的程序由用户根据业务场景进行配置。

**修复方法：**

修改/etc/sudoers配置文件，对需要以root执行指定特权的用户配置权限。

```bash
# vim /etc/sudoers
test_sudo  ALL=(root)  /bin/ping
```

上一行配置一共包含四个字段，如上举例中：

第一个字段test_sudo为用户账号，实际配置时还可以指定为某一用户组，这样该用户组内的所有用户账号均可按后边的规则执行sudo；

第二个字段ALL意思是在任何主机名下都适用；

第三个字段root表明第一个字段所设定的用户账号或用户组可以切换到root下执行特权程序；

第四个字段中/bin/ping即为指定的特权程序，多个特权程序用逗号隔开。
### 2.4.6 确保sudoers不能配置低权限用户可写的脚本

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

sudo可以使设定的普通用户以root权限执行某些特定的程序，与之对应的配置文件为/etc/sudoers。管理员用户可以配置相应的规则使某些脚本或二进制文件以root的权限运行，所以sudo配置的脚本应该只有root可写，不能配置低权限用户可写的脚本，若配置了低权限用户可写的脚本则该用户可以通过修改该脚本实现提权操作。

**规则影响：**

无

**检查方法：**

检查sudo配置文件/etc/sudoers，检查特权程序是否为低权限用户可写。

```bash
# grep "(root)" /etc/sudoers
test_sudo  ALL=(root)  /bin/xxx.sh
# ll /bin/xxx.sh
-rw-------. 1 root root 451 Mar 27 17:00 /bin/xxx.sh
```

**修复方法：**

例如一个/etc/sudoers配置文件中的脚本为低权限用户可写，则用户需要根据实际的业务场景进行修复：

* 修复方法1

  修改/etc/sudoers配置文件中的脚本的文件权限，去除掉低特权用户的可写权限以防止该用户实现提权操作。

* 修复方法2

  修改/etc/sudoers配置文件删除低权限用户可配置的脚本文件，防止低权限用户实现提权操作
### 2.4.7 确保普通用户不能借助pkexec配置提权root

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

pkexec命令可以使一个普通用户拥有超级用户或其他用户的权限，当验证通过后便会以超级用户的权限来执行相应的程序。pkexec为用户变更身份提供了便捷的路径，但是如果不加约束的使用pkexec命令，会给系统带来潜在的安全风险。通过对用户使用pkexec访问root账号的权限进行限制，限制了其他账号的使用。可以提高系统账号使用的安全性。

openEuler默认配置使用pkexec需要验证root口令，且仅有root可获得系统管理员权限。

**规则影响：**

普通用户不能使用pkexec。

**检查方法：**

检查/etc/polkit-1/rules.d/50-default.rules中是否配置了仅root用户可以使用pkexec：

```bash
# cat /etc/polkit-1/rules.d/50-default.rules
/* -*- mode: js; js-indent-level: 4; indent-tabs-mode: nil -*- */

// DO NOT EDIT THIS FILE, it will be overwritten on update
//
// Default rules for polkit
//
// See the polkit(8) man page for more information
// about configuring polkit.

polkit.addAdminRule(function(action, subject) {
    return ["unix-user:0"];
});

```

**修复方法：**

修改/etc/polkit-1/rules.d/50-default.rules配置文件，仅root用户可以使用pkexec：

```bash
# vim /etc/polkit-1/rules.d/50-default.rules
polkit.addAdminRule(function(action, subject) {
    return ["unix-user:0"];
});
```
### 2.4.8 确保su命令继承用户环境变量不会引入提权

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

su命令可以使一个普通用户拥有超级用户或其他用户的权限，它经常被用于从普通用户账号切换到系统root账号。su命令为用户变更身份提供了便捷的途径，但如果不加约束的使用su命令，会给系统带来潜在的风险，su命令切换用户时不会自动为用户设置PATH。如果通过su切换用户后系统会自动初始化环境变量PATH，则可以有效防范由于继承环境变量PATH而导致的提权问题。

openEuler默认设置su完成后，PATH会自动初始化。


**规则影响：**

无

**检查方法：**

检查/etc/login.defs中是否配置了自动初始化环境变量PATH，即ALWAYS_SET_PATH=yes：

```bash
# cat /etc/login.defs | grep ALWAYS_SET_PATH=yes
ALWAYS_SET_PATH=yes
```

**修复方法：**

修改/etc/login.defs配置文件添加如下配置，使切换用户后系统会自动初始化环境变量PATH：

```bash
# vim /etc/login.defs
ALWAYS_SET_PATH=yes
```
### 2.4.9 避免root用户本地接入系统

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

root是Linux系统中的超级特权用户，具有所有Linux系统资源的访问权限。如果允许直接使用root账号登录Linux系统对系统进行操作，会带来很多潜在的安全风险，为了规避由此带来的风险，应禁止直接使用root帐号登录操作系统，仅在必要的情况通过其他技术手段（如：sudo或su）间接的使用root账号。

由于root账号拥有最高权限，直接使用root登录存在如下风险：

* 高危误操作可能直接导致服务器瘫痪，例如误删除、修改系统关键文件；

* 如果有多人需要root权限操作，则root口令将有多人保管，容易导致口令泄露，同时增加了口令维护成本。

openEuler默认不进行配置，如果实际场景中不存在需要使用root账号在本地登录的情况，建议禁用root账号本地登录。

**规则影响：**

root账号无法本地接入系统。

**检查方法：**

* 检查/etc/pam.d/system-auth文件中是否添加了account类型的pam_access.so模块，且该模块必须在sufficient控制行之前加载：

  ```bash
  # cat /etc/pam.d/system-auth
  account     required      pam_unix.so
  account     required      pam_faillock.so
  account     sufficient    pam_localuser.so
  account     sufficient    pam_succeed_if.so uid < 1000 quiet
  ```

* 并且，检查/etc/security/access.conf文件中是否设置对root用户登录tty1的限制：

  ```bash
  # grep "^\-:root" /etc/security/access.conf
  ```

* 使用串口尝试登录root账号，确认是否拒绝登录。如果拒绝登录，串口打印信息如下：

  ```bash
  Authorized users only. All activities may be monitored and reported.
  localhost login: root
  Password:
  
  Permission denied 
  ```

**修复方法：**

* 在/etc/pam.d/system-auth文件中添加了account类型的pam_access.so模块，且该模块必须在sufficient控制行之前加载：

  ```bash
  # vim /etc/pam.d/system-auth
  …
  account     required      pam_unix.so
  account     required      pam_faillock.so
  account     required      pam_access.so
  account     sufficient     pam_localuser.so
  …
  ```

* 在/etc/security/access.conf文件中添加对root用户登录tty1的限制：

  ```bash
  # vim /etc/security/access.conf
  -:root:tty1
  ```
### 2.4.10 避免使用标签为unconfined_service_t的程序

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

SELinux设置unconfined_service_t标签的目的是使一些未配置SELinux策略的第三方服务进程不受约束地运行。默认情况下，systemd运行标签为bin_t或usr_t（一般位于/usr/bin、/opt等目录下）的第三方应用程序时，产生的进程标签为unconfined_service_t。

与其他高权限标签（如unconfined_t、initrc_t等）的区别是，unconfined_service_t只有极少的域转换规则，这意味着即使进程运行那些已经配置过SELinux策略的应用程序，新进程的标签也依然为unconfined_service_t，进程配置的SELinux策略也不会生效，如果被攻击会对系统造成较大的影响。

**规则影响：**

标签为unconfined_service_t的程序运行受限制

**检查方法：**

运行以下命令，若返回值为空，表示当前系统中没有标签为unconfined_service_t的进程：

```bash
# ps -eZ | grep unconfined_service_t
```

**修复方法：**

为应用程序配置合理的SELinux策略，并添加域转换规则，使其被执行时转换到配置策略的进程标签。
## 2.5 完整性
### 2.5.1 应当启用IMA度量

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

IMA（Integrity Measurement Architecture）完整性度量架构是内核提供的完整性保护功能，开启IMA时，可基于用户自定义的策略为系统中的重要文件提供完整性度量，度量结果可被用于本地以及远程完整性证明。

系统未开启IMA度量功能时，无法实时记录关键文件的摘要信息，不能识别对文件内容或属性的篡改。本地证明、远程证明等保护系统完整性的功能依赖于IMA度量提供的摘要值，因此也无法使用，或者完整性保护不全。

IMA全局策略配置与具体环境相关，通常情况下完整性保护只针对于不可变文件（如可执行文件、动态库等），如果策略配置不当，可能导致性能及内存开销过大，建议用户根据自身情况决定是否开启IMA，并配置正确的策略。

注意：由于IMA只是全局完整性保护机制中的度量部分，要完整使用需依赖TPM 2.0及远程证明服务，本规范仅对IMA度量部分进行说明、建议。如果系统未集成TPM 2.0及远程证明服务，则不应启用IMA度量功能。

IMA度量不支持容器环境和虚拟机环境，且要求UEFI启动，不支持Legacy模式。

**规则影响：**

* 开启IMA度量会导致系统启动时间和文件访问时间有轻微增加。
* 如果策略配置不当（如对实时变化的日志文件、临时文件等进行度量），可导致度量日志增长过快、占用系统内存过大，且度量日志所占用内存在系统下次重启前不会被释放，进而影响业务正常运行。另外由于被度量文件一直在变化，引发度量值变化，而远程证明基线值无法同步更新，导致远程证明失败，失去完整性保护的意义。

**检查方法：**

* 首先确认当前内核启动参数中是否配置了integrity=1，如果查不到该参数，则说明IMA没有开启：

  ```bash
  # cat /proc/cmdline | grep integrity=1
  BOOT_IMAGE=/vmlinuz-<kernel version> root=/dev/mapper/openeuler-root ro resume=/dev/mapper/openeuler-swap rd.lvm.lv=openeuler/root rd.lvm.lv=openeuler/swap crashkernel=512M quiet  integrity=1
  ```

* 确认IMA开启后，查看/sys/kernel/security/ima/runtime_measurement_count文件中存储的度量记录数，如果该值大于1，则表示已配置IMA度量策略：

  ```bash
  # cat /sys/kernel/security/ima/runtime_measurements_count
  2053
  ```

**修复方法：**

* 在/boot/efi/EFI/openEuler/grub.cfg文件中配置启动参数“integrity=1 ima_appraise=off evm=ignore”（其中后两个参数可不配置），并重启系统：

  ```bash
  # vim /boot/efi/EFI/openEuler/grub.cfg
          linuxefi   /vmlinuz-<kernel version> root=/dev/mapper/openeuler-root ro resume=dev/mapper/openeuler-swap rd.lvm.lv=openeuler/root rd.lvm.lv=openeuler/swap crashkernel=512M integrity=1 ima_appraise=off evm=ignore
  ```

* 配置度量策略，一共有两种方式：

  在/etc/ima目录下添加策略文件ima-policy，该方式比较灵活，可以在ima-policy文件中自定义各自策略：

  ```bash
  # vim /etc/ima/ima-policy
  <ima policy lines>
  ```

  在启动参数中配置ima_policy=<tcb/exec_tcb>，该方式使用系统默认的几种策略（默认策略度量文件范围大，请谨慎使用），并重启系统：

  ```bash
  # vim /boot/efi/EFI/openEuler/grub.cfg
          linuxefi   /vmlinuz-<kernel version> root=/dev/mapper/openeuler-root ro resume=dev/mapper/openeuler-swap rd.lvm.lv=openeuler/root rd.lvm.lv=openeuler/swap crashkernel=512M integrity=1 ima_policy=tcb
  ```
### 2.5.2 应当启用aide入侵检测

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

aide（advanced intrusion detection environment）是一款入侵检测工具，可以用来检查系统中文件和目录的完整性，识别遭到恶意篡改的文件或目录。其完整性检查的原理是先构造一个基准数据库，该数据库包含文件或目录的一些属性如权限、所属用户等，在进行完整性检查时将当前系统的状态与基准数据库进行对比得出检查结果，最后报告当前系统的文件或目录变更情况，即检查报告。

启用aide入侵检测能有效识别恶意篡改文件或目录的行为，从而提升系统完整性安全。需要检查的文件或目录可以按需配置，灵活性高，用户只需要查询检查报告即可以判断是否存在恶意篡改行为。

**规则影响：**

需检查的文件越多，检查过程所需时间越长。如果用户启用aide，应根据自身业务场景，合理配置检查策略。

**检查方法：**

* 检查是否安装了aide软件包（如果返回-bash: aide: command not found，表示未安装）：

  ```bash
  # aide --version
  Aide 0.16
  ```

* 检查/etc/aide.conf文件中是否已经配置需要监控的文件或目录，举例仅表示默认配置监控目录中的/boot目录，用户若自行配置了需要监控的文件或目录，则确认相应的文件或目录已配置即可：

  ```bash
  # grep boot /etc/aide.conf | grep NORMAL
  /boot  NORMAL
  ```

* 检查是否存在基准数据库：

  ```bash
  # ls /var/lib/aide/aide.db.gz
  /var/lib/aide/aide.db.gz
  ```

**修复方法：**

* 如果未安装aide，则使用yum或dnf命令安装软件包：
  ```bash
  yum install aide
  或
  dnf install aide
  ```
* 在配置文件/etc/aide.conf中配置需要被监控的文件或目录。/etc/aide.conf中默认已经配置了部分需要监控的目录，包括/boot, /bin, /lib, /lib64等重要目录。用户可以根据需要，自行添加需要监控的文件或目录：

  ```bash
  # vim /etc/aide.conf
  /boot   NORMAL
  /bin    NORMAL
  /lib    NORMAL
  /lib64  NORMAL
  <add new folders>
  ```

* 生成基准数据库，执行初始化命令后，在/var/lib/aide目录下生成aide.db.new.gz，将其重命名aide.db.gz，即为基准数据库：

  ```bash
  # aide --init
  # mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
  ```

* 入侵检查，执行aide --check; 检查的结果会在屏幕打印，同时会保存到/var/log/aide/aide.log日志文件中：

  ```bash
  # aide --check
  ```

* 更新基准数据库：

  ```bash
  # aide --update
  # mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
  ```
## 2.6 数据安全
### 2.6.1 应当启用haveged服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

haveged服务提供了一个易用的、不可预测的随机数生成器，生成的随机数用于补充系统熵池，可解决某些情况下系统熵过低的问题。建议在有加解密或生成密钥需求的场景下（例如使用openssl和gnutls）都开启此服务。

如果haveged服务没有开启，需要生成强伪随机数的进程从/dev/random取值时，会因为取不到足够的值而陷入等待，直至取到新的随机字节后才返回。

**规则影响：**

无

**检查方法：**

检查环境中haveged服务是否处于正常运行状态：

```bash
# systemctl is-active haveged
active
```

如果显示处于active状态，说明haveged服务正在运行，反之如果显示处于inactive状态，说明服务未开启。

**修复方法：**

开启haveged服务：

```bash
# systemctl start haveged
```

如果要将其设置为随系统启动，可以这样配置：

```bash
# systemctl enable haveged.service
```
### 2.6.2 应当设置全局加解密策略配置不低于DEFAULT

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

系统全局加解密策略用于指定加解密组件允许的算法，通过修改/etc/crypto-policies/config配置文件可以改变预置的安全策略级别，从而改变应用程序可使用的算法集。

openEuler系统默认配置DEFAULT策略，提供LEGACY、DEFAULT、NEXT、FUTURE、FIPS可供选择，建议用户设置不低于DEFAULT的策略级别，即禁止设置LEGACY模式。

LEGACY：LEGACY策略可确保与旧系统的最大兼容性，但是该策略的安全性较低。该策略提供的安全级别至少为64位。
DEFAULT：DEFAULT策略是符合当前标准的默认策略。该策略提供的安全级别至少为80位。
NEXT：NEXT策略是为即将发布的操作系统准备的策略。该策略提供的安全级别至少为112位（注：DNSSec所需的SHA-1签名和其他仍普遍使用的SHA-1签名除外）。
FUTURE：FUTURE策略为安全级别较高的策略，可以抵御近期大多数的攻击方式。该策略提供的安全级别至少为128位。
FIPS：FIPS策略是符合FIPS 140-2要求的策略。该策略提供的安全级别至少为112位。

**规则影响：**

如果全局加解密策略设置过于宽松，将允许使用不安全加解密算法，降低系统整体安全性。

如果全局加解密策略设置过于严格，则可能由于客户端不支持更加安全的加解密算法，而导致存在兼容性问题。

如果业务程序未使用系统加解密模块，而是自行调用第三方加解密算法库进行操作，则不受影响。

**检查方法：**

检查环境中/etc/crypto-policies/config文件是否未配置LEGACY模式，如果返回信息为空，或者仅返回位于注释信息中的LEGACY字段，表示未配置LEGACY：

```bash
# cat /etc/crypto-policies/config | grep "LEGACY"
```

亦可通过如下方式检查当前配置的模式：

```bash
# cat /etc/crypto-policies/config | grep -v "^#"
DEFAULT
```

**修复方法：**

在/etc/crypto-policies/config文件中配置合适的策略：

```bash
# vim /etc/crypto-policies/config
DEFAULT
```
## 3 运行和服务
## 3.1 网络
### 3.1.1 避免使用不常见网络服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

一些不常见的协议，往往使用场景较少，社区发展较慢，安全问题不易被快速解决，如果未关闭这些并不使用的协议，可能导致攻击者利用协议或代码漏洞进行攻击。

流控制传输协议（SCTP，Stream Control Transmission Protocol）是一种在网络连接两端之间同时传输多个数据流的协议，SCTP提供的服务与UDP和TCP类似。

透明进程间通信（TIPC，Transparent Inter-process Communication）是一种用于进程间通信的网络通信协议，原本是为集群间通信特别设计的。它允许设计人员能够创建可以和其它应用快速可靠通信的应用，无须考虑其它需要通信的应用在集群环境中的位置。

如果业务场景不需要使用SCTP和TIPC等服务，要求从内核中关闭支持，减小攻击场景。

**规则影响：**

无

**检查方法：**

- 使用modprobe命令检查sctp，如果输出“install /bin/true”，表示sctp已经被禁止使用；如果输出“insmod /lib/modules/(kernel version)/kernel/net/sctp/sctp.ko”，表示未被禁止，并列出ko所在目录；如果输出“modprobe: FATAL: Module sctp not found in directory /lib/modules/(kernel version)”，表示不存在该ko文件，可不用处理：

  ```bash
  # modprobe -n -v sctp
  install /bin/true 
  ```

- 使用modprobe命令检查tipc，如果输出“install /bin/true”，表示tipc已经被禁止使用；如果输出“insmod /lib/modules/(kernel version)/kernel/net/tipc/tipc.ko”，表示未被禁止，并列出ko所在目录，根据平台不同，即使已经禁用tipc，命令执行后也可能会列出tipc的依赖ko，如udp_tunnel.ko和ip6_udp_tunnel.ko，可不用处理；如果输出“modprobe: FATAL: Module tipc not found in directory /lib/modules/(kernel version)”，表示不存在该ko文件，可不用处理：

  ```bash
  # modprobe -n -v tipc
  insmod /lib/modules/(kernel version)/kernel/net/ipv4/udp_tunnel.ko 
  insmod /lib/modules/(kernel version)/kernel/net/ipv6/ip6_udp_tunnel.ko
  install /bin/true
  ```

**修复方法：**

在/etc/modprobe.d/目录下，添加一个任意文件名，并以.conf为后缀的配置文件，属主和属组均为root, 权限600，按照如下格式填入内容，即可禁用sctp和tipc协议：

```bash
# vim /etc/modprobe.d/test.conf
install sctp /bin/true
install tipc /bin/true
```
### 3.1.2 避免使用无线网络

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

如果硬件设备包含WIFI等无线模块，且系统启用了WIFI，则服务器存在通过无线连接网络的可能，如果是不受控的连接，则一方面可能导致网络不稳定，另一方面增加了攻击面。

当不存在使用无线网络的场景，建议用户根据实际情况关闭无线网络功能。

**规则影响：**

依赖于无线网络的程序运行受限制

**检查方法：**

通过nmcli命令查看无线网络配置，如果WIFI和WWAN为enabled，表示已启用无线网络，例如：

```bash
# nmcli radio all
WIFI-HW  WIFI     WWAN-HW  WWAN    
enabled  enabled  enabled  enabled
```

**修复方法：**

通过nmcli命令可永久关闭WIFI和WWAN，即使系统重启也依旧保持关闭状态：

```bash
# nmcli radio all off
# nmcli radio all
WIFI-HW  WIFI     WWAN-HW  WWAN    
enabled  disabled  enabled  disabled
```
## 3.2 防火墙
### 3.2.1 应当启用firewalld服务

**级别：** 建议

**适用版本：** 全部

**规则说明：**

防火墙作为一种网络或系统之间强制实行访问控制的机制，是确保网络安全的重要手段。针对不同的需求和应用环境，可以量身定制出不同的防火墙系统。如果系统中没有配置防火墙服务，可能会导致系统被外部攻击、内部数据被窃取或篡改，大量无效流量浪费带宽、访问一些存在安全风险或业务无关的网站导致信息泄露。

对于连接到网络上的Linux系统来说，防火墙是必不可少的防御机制，它只允许合法的网络流量进出系统，而禁止其它任何网络流量，例如只限定允许的IP地址访问其SSH服务。因而，可以定制防火墙配置来满足任何特定需求和任何安全性需求。

openEuler提供firewalld、iptables、nftables三种常用的防火墙服务配置界面，其中firewalld底层实际调用iptables或nftables机制。

openEuler默认且建议启用firewalld服务，并关闭iptables、nftables服务。

三种防火墙服务建议只启用一种，不建议同时启用多种，如果多种防火墙规则设置不正确，可能导致规则冲突、防护混乱。

**规则影响：**

防火墙配置错误可能起不到防护作用，还有可能会导致正常的业务无法通信。

**检查方法：**

通过如下命令检查firewalld服务已经启用，并且iptables和nftables服务未被启用：

```bash
# service firewalld status 2>&1 | grep Active
Active: active (running) since Wed 2021-02-03  00:14:10 CST; 14h ago
# service iptables status 2>&1 | grep Active
Active: inactive (dead)
# service nftables status 2>&1 | grep Active
Active: inactive (dead)
```

**修复方法：**

使用如下方法启用firewalld服务，并配置永久生效：

```bash
# service firewalld start
# systemctl enable firewalld
```

使用如下方法关闭iptables和nftables服务，并配置永久生效：

```bash
# service iptables stop
# service nftables stop
# systemctl disable iptables
# systemctl disable nftables
```
### 3.2.2 应当配置正确的默认区域

**级别：** 建议

**适用版本：** 全部

**规则说明：**

Firewalld服务通过区域（zone）概念，允许将防火墙划分为几个独立的规则区域，不同的接口或源地址可以绑定到不同的区域，实现不同的控制逻辑。一个区域可以配置许多不同的网络接口或源，但反过来，一个接口或源只能绑定到一个区域中，避免报文进出时无法确定执行哪个区域的规则。

如果一个区域在处理接口或源的报文时，发现并没有显式的规则匹配，此时该区域可以决定如何处理该报文，比如接收、拒绝，或者直接交由默认区域处理。

可以根据实际业务场景，配置合适的默认区域，所有未被显式划分到指定区域的接口、源地址、连接等网络资源，都应该被分配到默认区域。

如果默认区域配置不合理，则可能对未绑定到其他区域的网络资源产生非预期的影响。

如果所有网络资源都已经显式的绑定到其他区域，且已经制定详尽的规则，默认区域未配置任何规则，则默认区域将不影响业务。但这不是推荐的做法。

openEuler firewalld服务共提供11种区域类型：Server、Workstation、block、dmz、drop、external、home、internal、public、trusted、work。默认配置为public。

**规则影响：**

无

**检查方法：**

使用firewall-cmd命令查询默认区域配置：

```bash
# firewall-cmd --get-default-zone
public
```

**修复方法：**

使用firewall-cmd命令配置默认区域：

```bash
# firewall-cmd --set-default-zone=<name of zone>
```
### 3.2.3 应当确保网络接口绑定正确区域

**级别：** 建议

**适用版本：** 全部

**规则说明：**

不同的防火墙区域可以制定不同的过滤策略，如果服务器网络比较复杂，有多个接口，且不同接口承担不同的业务功能，建议将接口配置到不同的区域，并制定不同的防火墙策略，比如外网业务接口不允许SSH访问，而内网管理接口可以开放SSH访问。如果所有接口都配置到一个区域中，防火墙策略不利于对不同接口进行不同配置，增加管理复杂度，降低防火墙安全防护的过滤效率，因配置问题，可能导致不该接收的报文未被拒绝或丢弃。

**规则影响：**

无

**检查方法：**

检查各个区域配置的接口情况：

```bash
# firewall-cmd --get-active-zones
public
  interfaces: eth0
work
  interfaces: eth1
```

**修复方法：**

使用firewall-cmd命令从指定区域移除接口：

```bash
# firewall-cmd --zone=work --remove-interface eth1
success
```

使用firewall-cmd命令往指定区域增加接口：

```bash
# firewall-cmd --zone=work --add-interface eth1
success
```

使用firewall-cmd命令将当前防火墙配置固化到配置文件中，使之永久生效：

```bash
# firewall-cmd --runtime-to-permanent
success
```
### 3.2.4 避免开启不必要的服务和端口

**级别：** 建议

**适用版本：** 全部

**规则说明：**

在区域中需要精确配置哪些接口、服务、端口等是要开启的，哪些是必须关闭的。正确配置后可以防止不被允许的报文被接收处理，减少服务器暴露的端口，减小攻击面。

如果配置不正确，原本应该被禁止的接口或端口被开放出去，攻击者就可以利用这些接口或端口实施攻击行为，增加服务器和其他网元的风险。

**规则影响：**

无

**检查方法：**

使用如下脚本查看所有active状态的区域，检查区域中接口、服务、端口等配置是否合理（此处public、work两个区域只是举例，配置的接口、服务、端口等需要根据实际部署情况确定）：

```bash
# for zone in $(firewall-cmd --get-active-zones | grep -v "^[[:space:]]"); do firewall-cmd --list-all --zone=$zone; done
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth1
  sources: 
  services: ssh mdns dhcpv6-client
  ports: 
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
	
work (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth2
  sources: 
  services: ssh mdns dhcpv6-client samba
  ports: 80/tcp
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules:
```

**修复方法：**

使用如下命令，删除指定区域中对应的服务、端口等：

```bash
# firewall-cmd --zone=work --remove-service samba
success
# firewall-cmd --zone=work --remove-port 80/tcp
success
# firewall-cmd --list-all --zone=work
work (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth1
  sources: 
  services: ssh mdns dhcpv6-client
  ports: 
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

使用firewall-cmd命令将当前防火墙配置固化到配置文件中，使之永久生效：

```bash
# firewall-cmd --runtime-to-permanent
success
```
### 3.2.5 应当启用iptables服务

**级别：** 建议

**适用版本：** 全部

**规则说明：**

Iptables是Linux操作系统提供的一套基于IPv4和IPv6过滤规则链的防火墙管理工具，同时提供防火墙服务。

Iptables服务区分IPv4和IPv6，所以需要分别配置策略和启闭服务。

openEuler默认且建议使用firewalld服务。如果必须使用iptables提供防火墙服务，则必须关闭firewalld和nftables服务。如果未启用任何防火墙服务，则将提高系统被攻击、篡改的可能。

三种防火墙服务建议只启用一种，不建议同时启用多种，如果多种防火墙规则设置不正确，可能导致规则冲突、防护混乱。

**规则影响：**

如果启用多个防火墙服务，可能导致因为策略配置不一致而造成业务中断。

**检查方法：**

通过如下方式检查iptables服务已经被启用，firewalld和nftables服务未被启用：

```bash
# service iptables status 2>&1 | grep Active
Active: active (exited) since Wed 2021-02-03 00:14:10 CST; 14h ago
# service firewalld status 2>&1 | grep Active
Active: inactive (dead)
# service nftables status 2>&1 | grep Active
Active: inactive (dead)
```

检查ip6tables服务是否已经启用：

```bash
# service ip6tables status 2>&1 | grep Active
Active: active (exited) since Wed 2021-02-03 00:14:10 CST; 14h ago
```

**修复方法：**

使用如下方法启用iptables服务，并配置永久生效：

```bash
# service iptables start
# systemctl enable iptables
```

使用如下方法启用ip6tables服务，并配置永久生效：

```bash
# service ip6tables start
# systemctl enable ip6tables
```

使用如下方法关闭firewalld和nftables服务，并配置永久生效：

```bash
# service firewalld stop
# service nftables stop
# systemctl disable firewalld
# systemctl disable nftables
```
### 3.2.6 应当正确配置iptables默认拒绝策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

通常情况下，iptables策略配置可以分为白名单方式和黑名单方式两种，建议通过白名单方式配置，只要不符合白名单中规则的链接，全部禁止。所以可以先配置对INPUT、OUTPUT、FORWARD链的DROP或REJECT策略，然后针对需要开放的端口和服务配置ACCEPT策略。

**规则影响：**

通过黑名单方式配置策略，由于未被配置为DROP或REJECT的链接都将被ACCEPT，容易因为遗漏而导致安全风险。

**检查方法：**

使用如下命令检查IPv4的INPUT、OUTPUT、FORWARD链默认是否为拒绝策略：

```bash
# iptables -L | grep -E "INPUT|OUTPUT|FORWARD"
Chain INPUT (policy DROP)
Chain FORWARD (policy DROP)
Chain OUTPUT (policy DROP)
```

使用如下命令检查IPv6的INPUT、OUTPUT、FORWARD链默认是否为拒绝策略：

```bash
# ip6tables -L | grep -E "INPUT|OUTPUT|FORWARD"
Chain INPUT (policy DROP)
Chain FORWARD (policy DROP)
Chain OUTPUT (policy DROP)
```

**修复方法：**

使用如下命令配置INPUT、OUTPUT、FORWARD链的默认策略为拒绝。需要注意的是，如果通过网络连接进行远程配置操作，那么策略被修改后网络就会断开，需要通过串口进行连接配置：

```bash
# iptables -A INPUT -j DROP
# iptables -A OUTPUT -j DROP
# iptables -A FORWARD -j DROP
```

通过如下命令使当前配置的策略永久生效：

```bash
# service iptables save
iptables: Saving firewall rules to /etc/sysconfig/iptables: [  OK  ]
```

配置IPv6默认策略：

```bash
# ip6tables -A INPUT -j DROP
# ip6tables -A OUTPUT -j DROP
# ip6tables -A FORWARD -j DROP
```

通过如下命令使当前配置的策略永久生效：

```bash
# service ip6tables save
ip6tables: Saving firewall rules to /etc/sysconfig/ip6tables: [  OK  ]
```
### 3.2.7 应当正确配置iptables loopback策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

回环地址是服务器上一个特殊的地址，以127.0.0.0/8表示，同网卡无关，主要用于本机进程间通信，不应该从网卡上收到源地址为127.0.0.0/8的报文，此类报文应该被丢弃。如果回环地址策略设置不正确，则可能导致本机进程间通信失败，或者从网卡收到欺骗报文。

服务器需要设置策略，允许接收和处理lo接口的回环地址报文，但拒绝从网卡收到的报文。

**规则影响：**

无

**检查方法：**

查看IPv4的INPUT、OUTPUT链是否已经正确配置回环地址策略：

```bash
# iptables -L INPUT -v -n
Chain INPUT (policy DROP 389 packets, 125K bytes)
 pkts bytes target     prot opt in     out     source               destination
 1089 81354 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22
   10   840 ACCEPT     all  --  lo     *       0.0.0.0/0            0.0.0.0/0
    0     0 DROP       all  --  *      *       127.0.0.0/8          0.0.0.0/0
# iptables -L OUTPUT -v -n
Chain OUTPUT (policy DROP 58 packets, 11780 bytes)
 pkts bytes target     prot opt in     out     source               destination
  871 94717 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp spt:22
   17  1428 ACCEPT     all  --  *      lo      0.0.0.0/0            0.0.0.0/0
```

查看IPv6的INPUT、OUTPUT链是否已经正确配置回环地址策略：

```bash
# ip6tables -L INPUT -v -n
Chain INPUT (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     all      lo     *       ::/0                 ::/0
    0     0 DROP       all      *      *       ::1                  ::/0
# ip6tables -L OUTPUT -v -n
Chain OUTPUT (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     all      *      lo      ::/0                 ::/0
```

**修复方法：**

通过如下命令设置允许接收和处理lo接口报文，拒绝源地址为127.0.0.0/8的报文。iptables是按照顺序进行规则匹配的，所以DROP规则必须被添加在另外两条规则之后，否则由于lo接口发出的报文源地址也是127.0.0.0/8，会被DROP规则丢弃：

```bash
# iptables -A INPUT -i lo -j ACCEPT
# iptables -A OUTPUT -o lo -j ACCEPT
# iptables -A INPUT -s 127.0.0.0/8 -j DROP
```

通过如下命令使当前配置的策略永久生效：

```bash
# service iptables save
iptables: Saving firewall rules to /etc/sysconfig/iptables: [  OK  ]
```

配置IPv6：

```bash
# ip6tables -A INPUT -i lo -j ACCEPT
# ip6tables -A OUTPUT -o lo -j ACCEPT
# ip6tables -A INPUT -s ::1 -j DROP
```

通过如下命令使当前配置的策略永久生效：

```bash
# service ip6tables save
ip6tables: Saving firewall rules to /etc/sysconfig/ip6tables: [  OK  ]
```
### 3.2.8 应当正确配置iptables INPUT策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

INPUT链的作用是对从外部接收的报文进行过滤，任何对外提供的服务，都需要配置对应的INPUT策略，开启相关的端口，外部客户端才能通过该端口访问该服务。

如果未配置，由于默认策略配置为DROP，所有外部尝试访问相关业务的报文都将被丢弃。

**规则影响：**

无

**检查方法：**

检查INPUT链配置的策略是否满足业务需要，如下例子中开启了目标端口为22的tcp报文通道（即SSH协议的默认端口），且不限制源、目标IP地址：

```bash
# iptables -L INPUT -v -n
Chain INPUT (policy DROP 2132 packets, 683K bytes)
 pkts bytes target     prot opt in     out     source               destination
 1207 90226 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22
```

检查IPv6：

```bash
# ip6tables -L INPUT -v -n
Chain INPUT (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     all      lo     *       ::/0                 ::/0
    0     0 DROP       all      *      *       ::1                  ::/0
    0     0 ACCEPT     tcp      *      *       ::/0                 ::/0                 tcp dpt:22
```

**修复方法：**

通过如下命令新增ACCEPT策略到INPUT链：

```bash
# iptables -A INPUT -p <protocol> -s <source ip> -d <dest ip> --dport <dest port> -j ACCEPT
例如：
# iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

通过如下命令使当前配置的策略永久生效：

```bash
# service iptables save
iptables: Saving firewall rules to /etc/sysconfig/iptables: [  OK  ]
```

配置IPv6：

```bash
# ip6tables -A INPUT -p <protocol> -s <source ip> -d <dest ip> --dport <dest port> -j ACCEPT
例如：
# ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
```

通过如下命令使当前配置的策略永久生效：

```bash
# service ip6tables save
ip6tables: Saving firewall rules to /etc/sysconfig/ip6tables: [  OK  ]
```
### 3.2.9 应当正确配置iptables OUTPUT策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

服务器外发报文主要有两种情况，一种是主机进程主动连接外部服务器，比如http访问，或者外发数据到日志服务器等，另一种是外部访问本机服务，本机进行回复的报文。

如果未配置OUTPUT策略，由于默认策略是DROP，服务器所有外发报文都将被丢弃。

**规则影响：**

无

**检查方法：**

检查OUTPUT链配置的策略是否满足业务需要，如下例子中开启了源端口为22的tcp报文通道（即SSH协议的默认端口），且不限制源、目标IP地址：

```bash
# iptables -L OUTPUT -v -n
Chain OUTPUT (policy DROP 30 packets, 9840 bytes)
 pkts bytes target     prot opt in     out     source               destination
 1383  156K ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp spt:22
```

检查IPv6：

```bash
# ip6tables -L OUTPUT -v -n
Chain OUTPUT (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     all      *      lo      ::/0                 ::/0
    0     0 ACCEPT     tcp      *      *       ::/0                 ::/0                 tcp spt:22
```

**修复方法：**

通过如下命令新增ACCEPT策略到OUTPUT链：

```bash
# iptables -A OUTPUT -p <protocol> -s <source ip> -d <dest ip> --sport <src port> -j ACCEPT
例如：
# iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
```

通过如下命令使当前配置的策略永久生效：

```bash
# service iptables save
iptables: Saving firewall rules to /etc/sysconfig/iptables: [  OK  ]
```

配置IPv6：

```bash
# ip6tables -A OUTPUT -p <protocol> -s <source ip> -d <dest ip> --sport <src port> -j ACCEPT
例如：
# ip6tables -A OUTPUT -p tcp --sport 22 -j ACCEPT
```

通过如下命令使当前配置的策略永久生效：

```bash
# service ip6tables save
ip6tables: Saving firewall rules to /etc/sysconfig/ip6tables: [  OK  ]
```
### 3.2.10 应当正确配置iptables INPUT、OUTPUT关联策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

虽然可以通过配置协议、ip和端口等，将进出服务器的报文策略配置到INPUT和OUTPUT链，但有些情况下会比较复杂，比如客户端通过某端口访问服务器，但服务器在返回响应报文时并不一定从原端口返回，可能使用随机的源端口，这种情况下通过sport参数很难配置准确的策略。

此时需要考虑使用关联链接的方式配置策略，如果一个外发的报文属于一个已经存在的网络链接，则直接放行；如果一个接收的报文，属于一个已经存在的网络链接，也直接放行。因为这些已经存在的链接必定是经过其他策略过滤和检查的，否则无法建立。

如果不通过关联链接的方式配置策略，则需要将所有可能的链接情况全部分析清楚并配置对应的策略，如果配置过松，可能导致安全风险，如果配置过严，可能导致业务中断。

**规则影响**：

无

**检查方法：**

检查INPUT和OUTPUT链是否配置了关联策略：

```bash
# iptables -L
Chain INPUT (policy DROP)
target     prot opt source               destination
ACCEPT     tcp  --  anywhere             anywhere             state ESTABLISHED
ACCEPT     udp  --  anywhere             anywhere             state ESTABLISHED
ACCEPT     icmp --  anywhere             anywhere             state ESTABLISHED

Chain FORWARD (policy DROP)
target     prot opt source               destination

Chain OUTPUT (policy DROP)
ACCEPT     tcp  --  anywhere             anywhere             state NEW,ESTABLISHED
ACCEPT     udp  --  anywhere             anywhere             state NEW,ESTABLISHED
ACCEPT     icmp --  anywhere             anywhere             state NEW,ESTABLISHED
```

检查IPv6：

```bash
# ip6tables -L
Chain INPUT (policy DROP)
target     prot opt source               destination
ACCEPT     all      anywhere             anywhere
DROP       all      localhost            anywhere
ACCEPT     tcp      anywhere             anywhere             tcp dpt:ssh
ACCEPT     tcp      anywhere             anywhere             state ESTABLISHED
ACCEPT     udp      anywhere             anywhere             state ESTABLISHED
ACCEPT     icmp     anywhere             anywhere             state ESTABLISHED

Chain FORWARD (policy DROP)
target     prot opt source               destination

Chain OUTPUT (policy DROP)
target     prot opt source               destination
ACCEPT     all      anywhere             anywhere
ACCEPT     tcp      anywhere             anywhere             tcp spt:ssh
ACCEPT     tcp      anywhere             anywhere             state NEW,ESTABLISHED
ACCEPT     udp      anywhere             anywhere             state NEW,ESTABLISHED
ACCEPT     icmp     anywhere             anywhere             state NEW,ESTABLISHED
```

**修复方法：**

通过如下命令配置OUTPUT链的tcp、udp和icmp策略，允许所有新建和已建立链接的报文外发；配置INPUT链的tcp、udp和icmp策略，允许所有已建立链接的报文接收：

```bash
# iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
# iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
# iptables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT
```

通过如下命令使当前配置的策略永久生效：

```bash
# service iptables save
iptables: Saving firewall rules to /etc/sysconfig/iptables: [  OK  ]
```

配置IPv6：

```bash
# ip6tables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
# ip6tables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
# ip6tables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
# ip6tables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
# ip6tables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
# ip6tables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT
```

通过如下命令使当前配置的策略永久生效：

```bash
# service ip6tables save
ip6tables: Saving firewall rules to /etc/sysconfig/ip6tables: [  OK  ]
```
### 3.2.11 应当启用nftables服务

**级别：** 建议

**适用版本：** 全部

**规则说明：**

nftables是Linux内核的子系统，提供对网络数据包的过滤和分类，nftables替换了Netfilter的iptables部分。与iptables相比，nftable更容易扩展到新协议，nftables将在未来替代iptables。另外，nftables不同于firewalld和iptables，操作系统默认未配置任何策略，需要管理员手工配置。

需要注意的是，openEuler默认且建议使用firewalld服务。如果必须使用nftables提供防火墙服务，则必须关闭firewalld和iptables服务。如果未启用任何防火墙服务，则将提高系统被攻击、篡改的可能。

三种防火墙服务建议只启用一种，不建议同时启用多种，如果多种防火墙规则设置不正确，可能导致规则冲突、防护混乱。

**规则影响：**

如果启用多个防火墙服务，可能导致因为策略配置不一致而造成业务中断。

**检查方法：**

通过如下方式检查nftables服务已经被启用，firewalld和iptables服务未被启用：

```bash
# service nftables status 2>&1 | grep Active
Active: active (exited) since Wed 2020-12-16 07:04:32 CST; 6s ago
# service firewalld status 2>&1 | grep Active
Active: inactive (dead)
# service iptables status 2>&1 | grep Active
Active: inactive (dead)
```

**修复方法：**

使用如下方法启用nftables服务，并配置永久生效：

```bash
# service nftables start
# systemctl enable nftables
```

使用如下方法关闭firewalld和iptables服务，并配置永久生效：

```bash
# service firewalld stop
# service iptables stop
# systemctl disable firewalld
# systemctl disable iptables
```
### 3.2.12 应当配置nftables默认拒绝策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

从安全角度考虑，nftables基础链类似于iptables，（input、output、forward）需要配置所有报文的拒绝策略，然后再在基础链中添加允许策略，开放相关服务和端口。

如果没有配置基础链，或没有指定基础链的hook规则，报文将不会被nftables捕捉到，也就无法进行过滤处理。

**规则影响：**

如果基础链未配置DROP或REJECT策略，报文默认都将被ACCEPT，容易因为遗漏拒绝策略而导致安全风险。

**检查方法：**

通过如下方法检查是否配置了input、output和forward的DROP策略，注意举例中同时已经配置了SSH的input和output ACCEPT策略，如果不配置，通过SSH远程登录将断开：

```bash
# nft list ruleset
table inet test {
	chain input {
		type filter hook input priority 0; policy drop;
		tcp dport ssh accept
	}

	chain output {
		type filter hook output priority 0; policy drop;
		tcp sport ssh accept
	}

	chain forward {
		type filter hook forward priority 0; policy drop;
	}
}
```

**修复方法：**

首先创建table：

```bash
# nft add table inet <table name>
```

然后通过如下方法在table中配置input、output、forward基础链的drop策略，注意，配置后网络将可能断开：

```bash
# nft add chain inet <table name> <chain name> { type filter hook input priority 0\; policy drop\; }
# nft add chain inet <table name> <chain name> { type filter hook output priority 0\; policy drop\; }
# nft add chain inet <table name> <chain name> { type filter hook forward priority 0\; policy drop\; }
```

通过如下方式将当前配置的规则保存到配置文件中，以便系统重启后能够自动加载：

```bash
# nft list ruleset > /etc/sysconfig/nftables.conf
```

注意，上述方式保存配置文件会覆盖原有配置内容，亦可将当前规则导出到单独文件中，或者直接在文件中编写新规则，然后在/etc/sysconfig/nftables.conf配置文件中通过include方式加载，此种方式需要注意避免多个include规则文件内有重复规则：

```bash
# nft list ruleset > /etc/nftables/new_test_rules.nft
# echo "include \"/etc/nftables/new_test_rules.nft\"" >> /etc/sysconfig/nftables.conf
```
### 3.2.13 应当配置nftables loopback策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

回环地址是服务器上一个特殊的地址，以127.0.0.0/8表示，同网卡无关，主要用于本机进程间通信，不应该从网卡上收到源地址为127.0.0.0/8的报文，此类报文应该被丢弃。如果回环地址策略设置不正确，则可能导致本机进程间通信失败，或者从网卡收到欺骗报文。

服务器需要设置策略，允许接收和处理lo接口的回环地址报文，但拒绝从网卡收到的报文。

**规则影响：**

无

**检查方法：**

查看是否已经配置回环地址策略，input链需要配置从“lo”设备接收报文的ACCEPT策略，配置从非“lo”设备接收，且源地址为127.0.0.0/8的报文的DROP策略，在output链需要配置源地址为127.0.0.0/8的报文的ACCEPT策略：

IPv4配置：

```bash
# nft list ruleset
table inet test {
	chain input {
		type filter hook input priority 0; policy drop;
		tcp dport ssh accept
		iif "lo" accept
		iif != "lo" ip saddr 127.0.0.0/8 drop
	}

	chain output {
		type filter hook output priority 0; policy drop;
		tcp sport ssh accept
		ip saddr 127.0.0.0/8 accept
	}

	chain forward {
		type filter hook forward priority 0; policy drop;
	}
}
```

IPv6配置：

```bash
# nft list ruleset
table inet test {
	chain input {
		type filter hook input priority 0; policy drop;
		tcp dport ssh accept
		iif "lo" accept
		iif != "lo" ip6 saddr ::1 drop
	}

	chain output {
		type filter hook output priority 0; policy drop;
		tcp sport ssh accept
		ip6 saddr ::1 accept
	}

	chain forward {
		type filter hook forward priority 0; policy drop;
	}
}
```

**修复方法：**

通过如下方法添加input和output链的策略：

配置input链“lo”接口ACCEPT策略：

```bash
# nft add rule inet test input iif "lo" accept
```

配置IPv4 input链DROP策略，output链ACCEPT策略：

```bash
# nft add rule inet test input iif != "lo" ip saddr 127.0.0.0/8 drop
# nft add rule inet test output ip saddr 127.0.0.0/8 accept
```

配置IPv6 input链DROP策略，output链ACCEPT策略：

```bash
# nft add rule inet test input iif != "lo" ip6 saddr ::1 drop
# nft add rule inet test output ip6 saddr ::1 accept
```

通过如下方式将当前配置的规则保存到配置文件中，以便系统重启后能够自动加载：

```bash
# nft list ruleset > /etc/sysconfig/nftables.conf
```

注意，上述方式保存配置文件会覆盖原有配置内容，亦可将当前规则导出到单独文件中，或者直接在文件中编写新规则，然后在/etc/sysconfig/nftables.conf配置文件中通过include方式加载，此种方式需要注意避免多个include规则文件内有重复规则：

```bash
# nft list ruleset > /etc/nftables/new_test_rules.nft
# echo "include \"/etc/nftables/new_test_rules.nft\"" >> /etc/sysconfig/nftables.conf
```
### 3.2.14 应当正确配置nftables input策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

input链的作用是对从外部接收的报文进行过滤，任何对外提供的服务，都需要配置对应的input策略，开启相关的端口，外部客户端才能通过该端口访问该服务。

如果未配置，由于默认策略配置为DROP，所有外部尝试访问相关业务的报文都将被丢弃。

**规则影响：**

无

**检查方法：**

检查input链配置的策略是否满足业务需要，如下例子中开启了目标端口为22的tcp报文通道（即SSH协议的默认端口），且不限制源、目标IP地址：

```bash
# nft list chain inet test input
table inet test {
	chain input {
		type filter hook input priority 0; policy drop;
		tcp dport ssh accept
	}
}
```

**修复方法：**

通过如下命令新增ACCEPT策略到input链：

```bash
# nft add rule inet <table name> <chain name> <protocol> dport <port number> accept
例如：
# nft add rule inet test input tcp dport ssh accept
```

通过如下方式将当前配置的规则保存到配置文件中，以便系统重启后能够自动加载：

```bash
# nft list ruleset > /etc/sysconfig/nftables.conf
```

注意，上述方式保存配置文件会覆盖原有配置内容，亦可将当前规则导出到单独文件中，或者直接在文件中编写新规则，然后在/etc/sysconfig/nftables.conf配置文件中通过include方式加载，此种方式需要注意避免多个include规则文件内有重复规则：

```bash
# nft list ruleset > /etc/nftables/new_test_rules.nft
# echo "include \"/etc/nftables/new_test_rules.nft\"" >> /etc/sysconfig/nftables.conf
```
### 3.2.15 应当正确配置nftables output策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

服务器外发报文主要有两种情况，一种是主机进程主动连接外部服务器，比如http访问，或者外发数据到日志服务器等，另一种是外部访问本机服务，本机进行回复的报文。

如果未配置output策略，由于默认策略是DROP，服务器所有外发报文都将被丢弃。

**规则影响：**

无

**检查方法：**

检查output链配置的策略是否满足业务需要，如下例子中开启了源端口为22的tcp报文通道（即SSH协议的默认端口），且不限制源、目标IP地址：

```bash
# nft list chain inet test output
table inet test {
	chain output {
		type filter hook output priority 0; policy drop;
		tcp sport ssh accept
	}
}
```

**修复方法：**

通过如下命令新增ACCEPT策略到output链：

```bash
# nft add rule inet <table name> <chain name> <protocol> sport <port number> accept
例如：
# nft add rule inet test output tcp sport ssh accept
```

通过如下方式将当前配置的规则保存到配置文件中，以便系统重启后能够自动加载：

```bash
# nft list ruleset > /etc/sysconfig/nftables.conf
```

注意，上述方式保存配置文件会覆盖原有配置内容，亦可将当前规则导出到单独文件中，或者直接在文件中编写新规则，然后在/etc/sysconfig/nftables.conf配置文件中通过include方式加载，此种方式需要注意避免多个include规则文件内有重复规则：

```bash
# nft list ruleset > /etc/nftables/new_test_rules.nft
# echo "include \"/etc/nftables/new_test_rules.nft\"" >> /etc/sysconfig/nftables.conf
```
### 3.2.16 应当正确配置nftables input、output关联策略

**级别：** 建议

**适用版本：** 全部

**规则说明：**

虽然可以通过配置协议、ip和端口等，将进出服务器的报文策略配置到input和output链，但有些情况下会比较复杂，比如客户端通过某端口访问服务器，但服务器在返回响应报文时并不一定从原端口返回，可能使用随机的源端口，这种情况下通过sport参数很难配置准确的策略。

此时需要考虑使用关联链接的方式配置策略，如果一个外发的报文属于一个已经存在的网络链接，则直接放行；如果一个接收的报文，属于一个已经存在的网络链接，也直接放行。因为这些已经存在的链接必定是经过其他策略过滤和检查的，否则无法建立。

如果不通过关联链接的方式配置策略，则需要将所有可能的链接情况全部分析清楚并配置对应的策略，如果配置过松，可能导致安全风险，如果配置过严，可能导致业务中断。

**规则影响**：

无

**检查方法：**

检查input和output链是否配置了关联策略：

```bash
# nft list ruleset
table inet test {
	chain input {
		type filter hook input priority 0; policy drop;
		tcp dport ssh accept
		ip protocol tcp ct state established accept
		ip protocol udp ct state established accept
		ip protocol icmp ct state established accept
	}

	chain output {
		type filter hook output priority 0; policy drop;		
		ip protocol tcp ct state established,related,new accept
		ip protocol udp ct state established,related,new accept
		ip protocol icmp ct state established,related,new accept
	}

	chain forward {
		type filter hook forward priority 0; policy drop;
	}
}
```

**修复方法：**

通过如下命令配置output链的tcp、udp和icmp策略，允许所有新建和已建立链接的报文外发；配置input链的tcp、udp和icmp策略，允许所有已建立链接的报文接收：

```bash
# nft add rule inet test output ip protocol tcp ct state new,related,established accept
# nft add rule inet test output ip protocol udp ct state new,related,established accept
# nft add rule inet test output ip protocol icmp ct state new,related,established accept
# nft add rule inet test input ip protocol tcp ct state established accept
# nft add rule inet test input ip protocol udp ct state established accept
# nft add rule inet test input ip protocol icmp ct state established accept
```

通过如下方式将当前配置的规则保存到配置文件中，以便系统重启后能够自动加载：

```bash
# nft list ruleset > /etc/sysconfig/nftables.conf
```

注意，上述方式保存配置文件会覆盖原有配置内容，亦可将当前规则导出到单独文件中，或者直接在文件中编写新规则，然后在/etc/sysconfig/nftables.conf配置文件中通过include方式加载，此种方式需要注意避免多个include规则文件内有重复规则：

```bash
# nft list ruleset > /etc/nftables/new_test_rules.nft
# echo "include \"/etc/nftables/new_test_rules.nft\"" >> /etc/sysconfig/nftables.conf
```

## 3.3 SSH
### 3.3.1 确保SSH服务版本配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

如果使用SSH1，由于协议本身存在较多的未修复漏洞，且社区已不作为主流协议进行长期维护，容易使攻击者有机可乘，造成信息泄露、命令数据篡改等风险。

openEuler默认继承的OpenSSH组件使用SSH协议进行远程控制或在服务器之间传递文件，支持SSH 1.3、1.5和2.0协议，其中1.x协议简称SSH1，由于安全原因不允许使用；2.0协议简称为SSH2，目前无安全问题，要求使用。SSH1同SSH2互不兼容，所以要求服务端在使用SSH2之后，客户端也必须使用SSH 2.0协议。

当前openEuler默认使用SSH2。

**规则影响：**

无

**检查方法：**

通过如下命令，查看返回是否为2：

```bash
# grep "^Protocol" /etc/ssh/sshd_config
Protocol 2
```

**修复方法：**

修改/etc/ssh/sshd_config文件，将Protocol字段后面的数字修改为2，重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
Protocol 2
# systemctl restart sshd
```
### 3.3.2 确保SSH服务认证方式配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

配置合理的认证方式有利于确保用户及系统数据安全，通常情况下，对于人机账号，账号/口令方式比较合适；对于非交互式的登录场景，公私钥方式比较合适；而对于高安全风险场景，仅开启公私钥认证方式更合适。如果使用基于主机的身份认证，攻击者可通过域名污染或IP欺骗后无需口令直接入侵系统。

SSH服务本身提供多种认证方式，但出于安全考虑，禁止使用基于主机的身份认证。

openEuler默认使用账号/口令方式认证，在安装系统时，要求配置root管理员口令。

openEuler允许公私钥方式认证。

openEuler允许交互式-账号/口令方式认证。

根据业务场景需要，务必配置正确的认证方式。

**规则影响：**

无

**检查方法：**

通过如下方法，检查配置是否正确，此处IgnoreRhosts必须配置为yes，HostbasedAuthentication必须配置为no，PasswordAuthentication、ChallengeResponseAuthentication和PubkeyAuthentication至少有一个为yes：

```bash
# grep "^PasswordAuthentication\|^PubkeyAuthentication\|^ChallengeResponseAuthentication\|^IgnoreRhosts\|^HostbasedAuthentication" /etc/ssh/sshd_config
PasswordAuthentication yes
PubkeyAuthentication yes
ChallengeResponseAuthentication yes
IgnoreRhosts yes
HostbasedAuthentication no
```

**修复方法：**

- 启用账号/口令认证方式

  配置/etc/ssh/sshd_config文件，开启PasswordAuthentication选项，重启sshd服务，如下：

  ```bash
  # vim /etc/ssh/sshd_config
  PasswordAuthentication yes
  # systemctl restart sshd
  ```

- 启用公私钥认证方式

  配置/etc/ssh/sshd_config文件，开启PubkeyAuthentication选项，并配置公钥存储路径，重启sshd服务，例如：

  ```bash
  # vim /etc/ssh/sshd_config
  PubkeyAuthentication yes
  AuthorizedKeysFile      .ssh/authorized_keys
  # systemctl restart sshd
  ```

  客户端生成RSA公私钥，并把公钥拷贝到指定目录下即可，如上例中“.ssh/authorized_keys”目录。

- 启用交互式-账号/口令认证方式

  配置/etc/ssh/sshd_config文件，开启ChallengeResponseAuthentication选项，重启sshd服务，如下：

  ```bash
  # vim /etc/ssh/sshd_config
  ChallengeResponseAuthentication yes
  # systemctl restart sshd
  ```

- 关闭基于主机的认证

  配置/etc/ssh/sshd_config文件，开启IgnoreRhosts，关闭HostbasedAuthentication，重启sshd服务，如下：

  ```bash
  # vim /etc/ssh/sshd_config
  IgnoreRhosts yes
  HostbasedAuthentication no
  # systemctl restart sshd
  ```
### 3.3.3 确保SSH密钥交换算法配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

密钥交换是密码学中双方交换密钥以允许使用某种加密算法的过程。通过安全的密钥交换算法，双方可以安全地交换密钥，从而允许使用加密算法对要发送的消息进行加密，并对接收到的消息进行解密。设置SSH密钥交换算法，限制密钥交换这一阶段所能使用的算法。要注意的是，若配置的算法不安全，则会增加使用风险，因为弱算法在业界已经或者即将被破解。

推荐的安全算法如下（按优先级排序，openEuler已默认配置）：

curve25519-sha256

curve25519-sha256@libssh.org

diffie-hellman-group-exchange-sha256

可以根据实际业务场景进行修改配置，但所选择的算法必须符合业界安全标准。

**规则影响：**

如果SSH客户端不支持服务端配置的密钥交换算法，客户端将无法连接到SSH服务端。

**检查方法：**

检查/etc/ssh/sshd_config中是否配置了正确的密钥交换算法的字段：

```bash
# grep ^KexAlgorithms /etc/ssh/sshd_config
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
```

KexAlgorithms字段设置可用的SSH密钥交换算法，用户根据需要进行设置。

**修复方法：**

修改/etc/ssh/sshd_config，在该文件中设置SSH密钥交换算法，下面给出密钥交换算法示例，用户在设置的时候应根据需要进行设置，设置好密钥交换算法后需重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
# systemctl restart sshd
```
### 3.3.4 确保用户认证密钥算法配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

如果采用公私钥认证方式，则需要限制客户端公私钥算法，避免使用已经被业界淘汰的不安全算法。

推荐的安全算法如下（按优先级排序，openEuler已默认配置）：

ssh-ed25519

ssh-ed25519-cert-v01@openssh.com

rsa-sha2-256

rsa-sha2-512

RFC 4253中定义的ssh-rsa公钥算法使用了SHA1进行哈希运算，因此禁止使用。

**规则影响：**

如果SSH客户端不支持服务端配置的公私钥算法，客户端将无法连接到SSH服务端。

**检查方法：**

通过如下方法检查配置：

```bash
# grep "^PubkeyAcceptedKeyTypes" /etc/ssh/sshd_config
PubkeyAcceptedKeyTypes ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512
```

**修复方法：**

修改文件/etc/ssh/sshd_config的PubkeyAcceptedKeyTypes字段的算法列表，不同算法间通过逗号分隔，重启sshd服务，例如：

```bash
# vim /etc/ssh/sshd_config
PubkeyAcceptedKeyTypes ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512
# systemctl restart sshd
```
### 3.3.5 确保PAM认证使能

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

PAM（Pluggable Authentication Modules）是Linux平台上可插拔的认证模块，PAM提供了一系列的开源共享库文件（so），通过配置参数可以灵活控制相关认证过程。SSH通过配置PAM认证，可以基于Linux系统的用户认证管理模块完成SSH远程登录用户的认证授权和管理，相对比较方便和统一；否则SSH需要对认证过程进行管理，例如认证失败次数控制，账号是否锁定等，配置容易遗漏或无法达到PAM管理的效果。

openEuler SSH默认使用PAM认证。

**规则影响：**

无

**检查方法：**

使用grep命令查看配置：

```bash
# grep -i "^UsePAM" /etc/ssh/sshd_config
UsePAM yes
```

**修复方法：**

修改/etc/ssh/sshd_config文件，将UsePAM设置为yes，重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
UsePAM yes
# systemctl restart sshd
```

### 3.3.6 确保SSH服务MACs算法配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

消息认证算法MACs：密码学中，通信实体双方使用的一种验证机制，保证了消息数据完整性。若配置的算法不安全，则会增加使用风险，因为弱算法在业界已经或者即将被破解。

推荐的安全算法如下（按优先级排序，openEuler已默认配置）：

hmac-sha2-512

hmac-sha2-512-etm@openssh.com

hmac-sha2-256

hmac-sha2-256-etm@openssh.com

**规则影响：**

如果SSH客户端不支持服务端配置的MACs算法，客户端将无法连接到SSH服务端。

**检查方法：**

使用grep命令查看配置，如果返回为空，表示未配置：

```bash
# grep -i "^MACs" /etc/ssh/sshd_config
MACs hmac-sha2-512,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-256-etm@openssh.com
```

**修复方法：**

修改/etc/ssh/sshd_config文件，在该文件中设置SSH消息认证算法，下面给出消息认证算法示例，用户在设置的时候应根据需要进行设置，设置好消息认证算法后需重启sshd服务使之生效：

```bash
# vim /etc/ssh/sshd_config
MACs hmac-sha2-512,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-256-etm@openssh.com
# systemctl restart sshd
```
### 3.3.7 确保SSH服务密码算法配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

随着密码技术的发展以及计算能力的提升，一些密码算法已不再适合现今的安全领域。例如MD5算法，该算法已经于2004年由山东大学王小云教授的团队予以破解（人为构造出两个具有相同MD5值的信息），并且在2007年由密码学家Marc Stevens进一步扩展和改进该攻击，实现了数字证书伪造，其安全性已非常低下，因此， MD5不应用于所有密码学安全用途，包括用于数字签名，HMAC，口令单向保护、密钥派生、RNG等，但是，对于校验线路错误、校验介质损坏引起的比特跳变等非密码学安全用途，使用MD5不受本规范约束。又比如DES算法，因为密码学分析技术的发展和计算能力提升导致对其进行暴力破解成为可能，现有的暴力破解设备能将破解DES的时间减少到一天以内。这些算法统称为不安全密码算法，如果继续使用这些不安全的密码算法，有可能为数据带来风险。

强密码算法是指当前被业界普遍认可，在其适合的应用场景下安全强度相对该场景下的其它加密算法有相对优势，在合理的安全假设下具有可证明安全性或对其实施破解在计算上显著不可行的密码算法。

密码算法用于加密解密数据，若配置的算法不安全，则会增加使用风险，因为弱算法在业界已经或者即将被破解。

**规则影响：**

如果SSH客户端不支持服务端配置的加密算法，客户端将无法连接到SSH服务端。

**检查方法：**

使用grep命令查看配置，如果返回为空，表示未配置：

```bash
# grep -i "^Ciphers" /etc/ssh/sshd_config
Ciphers aes128-ctr,aes192-ctr,aes256-ctr,chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes256-gcm@openssh.com
```

**修复方法：**

修改/etc/ssh/sshd_config文件，在该文件中设置SSH密码算法，下面给出密码算法示例，用户在设置的时候应根据需要进行设置，设置好密码算法后需重启sshd服务使之生效：

```bash
# vim /etc/ssh/sshd_config
Ciphers aes128-ctr,aes192-ctr,aes256-ctr,chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes256-gcm@openssh.com
# systemctl restart sshd
```
### 3.3.8 禁止SSH服务配置加密算法覆盖策略

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

SSH服务加密算法的配置文件为/etc/ssh/sshd_config、/etc/sysconfig/sshd。当SSH服务正在运行中，用户可以编辑/etc/sysconfig/sshd文件从而覆盖加密算法策略。如果配置加密算法覆盖策略将允许用户配置安全性较低的加密算法、消息认证算法、密钥交换算法等，降低了系统的安全性。攻击者可以利用这些不安全的算法破解系统信息，增加了安全风险。

openEuler默认不配置加密算法覆盖策略。

**规则影响：**

无

**检查方法：**

检查SSH配置文件/etc/sysconfig/sshd，如果“CRYPTO_POLICY=”字段为空或该行被注释则说明没有配置加密算法覆盖策略，反之则说明配置了加密算法覆盖策略。

```bash
# grep "^\s*CRYPTO_POLICY=" /etc/sysconfig/sshd | cut -d "=" -f 2-
'-oCiphers=aes256-ctr,aes192-ctr,aes128-ctr -oMACS=hmac-sha2-512,hmac-sha2-256'
```

**修复方法：**

编辑SSH服务配置文件/etc/sysconfig/sshd删除加密算法策略或注释掉该行，重新加载sshd配置。

```bash
# vim /etc/sysconfig/sshd
  
方案 1 删除加密算法策略：
CRYPTO_POLICY=
方案 2 注释该行：
# CRYPTO_POLICY='-oCiphers=aes256-ctr,aes192-ctr,aes128-ctr -oMACS=hmac-sha2-512,hmac-sha2-256'
  
# systemctl reload sshd
```
### 3.3.9 确保禁用root用户通过SSH登录

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

SSH 配置文件：/etc/ssh/sshd_config中的PermitRootLogin参数指定root用户是否可以使用ssh登录。
不允许root用户通过SSH登录：要求系统管理员使用自己的个人账户进行SSH登录，然后通过sudo或 su提升权限到root。这样可在发生安全事件时提供清晰的审计线索。
在对此项安全建议进行配置前，应确认还有其他可用的系统管理员用户账号，否则在配置生效后，将可能导致无法进行SSH远程管理。

**规则影响：**

配置生效后，root用户不能通过ssh远程登录

**检查方法：**

执行以下命令，验证SSH的PermitRootLogin配置是否正确（同时满足如下两个命令行的检查）：

 ```bash
 # sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep permitrootlogin
 permitrootlogin no
 # grep -Ei '^\s*PermitRootLogin\s+yes' /etc/ssh/sshd_config
 Nothing is returned
 ```

**修复方法：**

修改/etc/ssh/sshd_config文件，将PermitRootLogin字段修改为no，重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
PermitRootLogin no
# systemctl restart sshd
```
### 3.3.10 应当正确配置SSH服务日志级别

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

SSH提供多种日志输出级别：QUIET、FATAL、ERROR、INFO、VERBOSE、DEBUG、DEBUG1、DEBUG2、DEBUG3。日志级别设置越高（例如QUIET、FATAL），打印的日志信息越少，有利于节约硬盘空间，但不利于管理员对SSH事件进行审计追溯；反之（例如DEBUG2、DEBUG3），日志打印量大，消耗硬盘空间多，记录的事件比较详细。

openEuler默认设置为VERBOSE，建议根据实际场景设置合理的日志级别，不建议设置DEBUG及以下级别，容易导致日志量过多。

**规则影响：**

无

**检查方法：**

使用grep命令查看日志级别配置，如下例中配置为VERBOSE：

```bash
# grep -i "^LogLevel" /etc/ssh/sshd_config
LogLevel VERBOSE
```

**修复方法：**

修改/etc/ssh/sshd_config文件，将LogLevel设置为相应的级别，重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
LogLevel VERBOSE
# systemctl restart sshd
```
### 3.3.11 应当正确配置SSH服务接口

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

通常情况下服务器存在多个网卡多个IP地址，IP地址应该进行相关的规划，哪些用于业务，哪些用于管理，所以并不是每个IP地址都需要侦听SSH连接，可以通过配置限制只有指定IP地址才能进行SSH连接，减小攻击面。未配置的IP地址无法通过SSH连接到服务器。

openEuler作为平台，无法确定现网场景，默认不配置。建议根据实际情况规划和配置。

**规则影响：**

无

**检查方法：**

如果已经配置侦听的地址，通过grep命令可以查询对应的配置（<ip addr>为实际已配置的ip地址），返回打印为空表示未配置：

```bash
# grep -i "^ListenAddress" /etc/ssh/sshd_config
ListenAddress <ip addr>
```

**修复方法：**

修改/etc/ssh/sshd_config文件，在ListenAddress字段后设置相应的IP地址，如果有多个，可以设置多行，重启sshd服务，如：

```bash
# vim /etc/ssh/sshd_config
ListenAddress <ip addr 1>
ListenAddress <ip addr 2>
# systemctl restart sshd
```
### 3.3.12 应当正确配置SSH并发未认证连接数

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

攻击者在不知道口令的情况下，可以通过建立大量的未完成认证的并发连接来消耗系统资源。

openEuler默认不配置，建议根据实际场景配置上限值。

**规则影响：**

如果正在进行认证的连接数达到上限，则新连接将被直接拒绝。

**检查方法：**

使用grep命令查看配置，如果返回为空，表示未配置：

```bash
# grep -i "^MaxStartups" /etc/ssh/sshd_config
maxstartups 10:30:60
```

**修复方法：**

修改/etc/ssh/sshd_config文件，配置maxstartups字段。

配置值为用冒号分隔的3个字段，其中第一个字段和最后一个字段分别表示连接数下限和上限，中间字段表示丢弃连接的比例，如：
```bash
# vim /etc/ssh/sshd_config
maxstartups 10:30:60
```
表示未完成认证的连接数达到10个以后，开始丢弃30%的连接申请，如果此时继续累积未完成认证的连接数达到60个，那么拒绝所有新增连接。

修改本配置需要重启sshd服务生效：
```bash
# systemctl restart sshd
```

### 3.3.13 应当正确配置单个SSH连接允许的并发会话数

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

SSH允许支持多路复用的客户端基于一个网络连接可以建立多个会话，MaxSessions限制每个网络连接允许建立的SSH并发会话数，可以防止系统资源被单个或少数连接无限制的占用，导致拒绝服务攻击。MaxSessions设置为1将禁用会话多路复用，即一个连接仅允许一个会话，而将其设置为0将阻止所有连接会话。

openEuler默认不在配置文件中配置，代码中会取默认值10，建议根据实际场景在配置文件中配置上限值。

**规则影响：**

如果单个客户端连接建立的会话数已经达到最大连接数，新建会话将被拒绝。

**检查方法：**

使用grep命令查看配置，如果返回为空，表示未配置：

```bash
# grep -i "^MaxSessions" /etc/ssh/sshd_config
MaxSessions 10
```

**修复方法：**

修改/etc/ssh/sshd_config文件，配置MaxSessions字段，该字段后面配置的数字表示限制的连接会话数，重启sshd服务，例如：

```bash
# vim /etc/ssh/sshd_config
MaxSessions 5
# systemctl restart sshd
```

说明：假设设置MaxSessions为5，修改配置并重新启动服务后，对已经存在的SSH会话不参与计数，也就是在该SSH通道还可以新建5个会话；如果修改配置后重新启动服务器，则一个通道只能存在5个会话。
### 3.3.14 禁止使用X11 Forwarding

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

SSH的X11 Forwarding功能允许在本地主机上执行远程主机的GUI程序。启用X11 Forwarding功能，则扩大了攻击面，存在被X11服务器端其他用户攻击的可能。如果业务场景中不需要，则必须禁止该功能。

openEuler默认关闭X11 Forwarding功能。

**规则影响：**

依赖于X11 Forwarding的程序执行受限制。

**检查方法：**

使用grep命令查看配置：

```bash
# grep -i "^X11Forwarding" /etc/ssh/sshd_config
X11Forwarding no
```

**修复方法：**

修改/etc/ssh/sshd_config文件，配置X11Forwarding字段，将该字段设置为no，重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
X11Forwarding no
# systemctl restart sshd
```
### 3.3.15 应当正确配置MaxAuthTries

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

MaxAuthTries值用于表示系统允许单次连接过程中，用户认证失败的次数，超过上限则自动断开连接。建议设置该值小于等于3。

如果该值配置比较大，则单次连接过程中客户端可以尝试多次认证失败，降低了攻击开销。如果该值未在配置文件中显式配置，系统默认为6。

**规则影响：**

认证失败次数超过上限，自动断开连接。

**检查方法：**

使用grep命令查看配置，如果返回为空，表示未配置：

```bash
# grep -i "^MaxAuthTries" /etc/ssh/sshd_config
MaxAuthTries 3
```

**修复方法：**

修改/etc/ssh/sshd_config文件，配置MaxAuthTries字段，该字段后面配置的数字表示限制的尝试次数，重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
MaxAuthTries 3
# systemctl restart sshd
```
### 3.3.16 禁止使用PermitUserEnvironment

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

PermitUserEnvironment允许用户设置SSH环境变量，该设置可能导致攻击者通过修改SSH环境变量进行相应攻击。

如果PermitUserEnvironment配置为yes，则攻击者可以通过修改SSH环境变量绕过安全机制，或者执行攻击代码。该配置必须关闭。

**规则影响：**

无

**检查方法：**

使用grep命令查看配置：

```bash
# grep -i "^PermitUserEnvironment" /etc/ssh/sshd_config
PermitUserEnvironment no
```

**修复方法：**

修改/etc/ssh/sshd_config文件，配置PermitUserEnvironment字段为no，重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
PermitUserEnvironment no
# systemctl restart sshd
```
### 3.3.17 应当正确配置LoginGraceTime

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

LoginGraceTime用于限制用户登录的时间，如果用户在LoginGraceTime限定的时间内没有完成登录动作，则自动断开连接。建议该值设置为小于或等于60秒。

如果该值设置过大，则攻击者可以利用大量未完成登录动作的连接来消耗服务器资源，从而导致正常管理员登录失败。如果该值未在配置文件中显式配置，系统默认为120秒。

**规则影响：**

无

**检查方法：**

使用grep命令查看配置：

```bash
# grep -i "^LoginGraceTime" /etc/ssh/sshd_config
LoginGraceTime 60
```

**修复方法：**

修改/etc/ssh/sshd_config文件，配置LoginGraceTime的值，该字段后面配置的数字表示限制的时间，单位秒，配置后重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
LoginGraceTime 60
# systemctl restart sshd
```
### 3.3.18 禁止SSH服务预设置authorized_keys

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

authorized_keys为远程主机的公钥，用户可以将该公钥存放于主目录$HOME/.ssh/authorized_keys文件中，用于公钥认证便可以直接登录系统。如果系统中预设authorized_keys，并且服务端开启了公私钥认证的登录方式，攻击者便可以绕过认证直接登录到指定的系统中对其进行攻击。所以系统中不能预设置authorized_keys。

openEuler默认不预设置authorized_keys。
注意，本规则仅对初始系统预设置进行约束，对于运行期间，按业务要求必须使用公钥认证的场景，可以例外。

**规则影响：**

无

**检查方法：**

使用grep命令查看配置，如果返回为空，表示未预设置authorized_keys：

```bash
# find /home/ /root/ -name authorized_keys 
/home/test/.ssh/authorized_keys
/root/.ssh/authorized_keys
```

**修复方法：**

删除被检测到的预设置authorized_keys，如/root/.ssh/authorized_keys文件：

```bash
# rm /root/.ssh/authorized_keys
```
### 3.3.19 禁止SSH服务预设置known_hosts

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

known_hosts为主机已经访问过的计算机的公钥，用户成功登录其他计算机后会自动将公钥信息保存在$HOME/.ssh/known_hosts中。当下次访问相同计算机时会校验公钥，如果校验失败则拒绝建立连接。所以系统中不能预设置known_hosts。

当系统中预设known_hosts时：

- 如果主机公钥正确，则在与目标主机建立连接的过程中不会发出警告，增加了安全风险。
- 如果主机公钥错误，则无法建立连接到目标主机。

openEuler默认不预设置known_hosts。

**规则影响：**

无

**检查方法：**

使用grep命令查看配置，如果返回为空，表示未预设置known_hosts：

```bash
# find /home/ /root/ -name known_hosts 
/home/test/.ssh/known_hosts
/root/.ssh/known_hosts
```

**修复方法：**

删除被检测到的文件，如/root/.ssh/known_hosts文件：

```bash
# rm /root/.ssh/known_hosts
```
### 3.3.20 禁止SSH服务配置弃用的选项

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

目前SSH服务通讯协议主要分为第一代和第二代，不同版本的通讯协议SSH服务的配置项并不兼容，而且某些低版本的配置项在新版本中已经被废除了。SSH服务端配置文件存放在/etc/ssh/sshd_config中，当前配置选项均为SSH第二代通信协议的配置选项，如果强行配置旧版本的配置项，会导致SSH服务进行自检时报错，且配置项并不生效。所以应禁止配置已经弃用的SSH选项。

openEuler默认不配置已经弃用的SSH选项。

**规则影响：**

无

**检查方法：**

使用SSH服务自检命令进行检查如果返回为空表示未出现错误，反之则说明配置了不兼容的选项：

```bash
# sshd -t
/etc/ssh/sshd_config line 147: Deprecated option RSAAuthentication
/etc/ssh/sshd_config line 149: Deprecated option RhostsRSAAuthentication
```

**修复方法：**

编辑SSH服务配置文件，删除已经废除的配置项，重启sshd服务：

```bash
# vim /etc/ssh/sshd_config
  
# RSAAuthentication yes
# RhostsRSAAuthentication no
  
# systemctl restart sshd
```
### 3.3.21 确保禁用SSH的TCP转发功能

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

将AllowTcpForwarding设置为no的作用是禁止SSH客户端进行TCP端口转发。TCP端口转发是通过SSH隧道在本地主机和远程主机之间传输数据的功能。通过禁用这一功能，可以限制用户在SSH会话中的数据传输和访问范围，从而增强系统的安全性。

配置后具体影响如下：

1. 限制数据传输： 禁用TCP端口转发可以防止用户在SSH会话中传输数据，从而降低了可能的数据泄露风险。
2. 减少攻击面：开启TCP端口转发可能会引入一些安全风险，如允许攻击者绕过网络安全措施或访问受限制的服务。禁用这一功能可以减少系统的攻击面。
3. 避免资源滥用：TCP端口转发可能占用服务器资源和带宽，禁用它可以避免资源被滥用。
4. 符合安全最佳实践：在某些情况下，如高度安全性要求的环境，禁用TCP端口转发可能是安全最佳实践之一。

**规则影响：**

禁用TCP端口转发可能会影响某些应用和用例，例如需要远程访问受限服务的情况。

**检查方法：**

执行以下命令，验证SSH的allowtcpforwarding配置是否正确（同时满足如下两个命令行的检查）：

```bash
# sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep allowtcpforwarding
allowtcpforwarding no
# grep -Ei '^\s*AllowTcpForwarding\s+yes\b' /etc/ssh/sshd_config
Nothing is returned
```

**修复方法：**

编辑/etc/ssh/sshd_config配置文件，修改AllowTcpForwarding参数，或添加以下代码，对AllowTcpForwarding参数进行配置：

```bash
# vim /etc/ssh/sshd_config
AllowTcpForwarding no
# systemctl restart sshd
```
### 3.3.22 应当正确配置认证黑白名单

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

SSH提供了黑白名单功能，可以设置账号或用户组的清单，允许或禁止某些账号或用户组的用户登录SSH，openEuler默认不配置，相关字段如下：

AllowUsers <userlist>

userlist是空格分割的允许登录的账号，不支持uid，可以是user@host格式，user和host将被单独检查，限制特定账号从特定主机上登录，名称里面可使用通配符*和?。配置后将自动禁止系统其他非授权账号登录ssh服务。

AllowGroups <grouplist>

grouplist是空格分隔的允许登录的用户组名称，不支持gid

DenyUsers <userlist>

userlist是空格分隔的拒绝登录的账号，不支持uid

DenyGroups <grouplist>

grouplist是空格分隔的拒绝登录的用户组名称，不支持gid

建议直接删除不使用的用户账号或用户组，而不是通过DenyUsers/DenyGroups进行拒绝登录。如果针对某个账号只允许或拒绝在某些客户端登录，可以通过user@host方式配置Allow或Deny规则。

Allow或Deny规则如果同时设置，则取并集，也就是说如果设置了Allow规则，那么被允许的用户账号或用户组之外的，都不允许登录；同时设置了Deny规则，那么在遵循Allow规则后，允许登录的用户账号或用户组范围内再匹配是否符合Deny规则，排除以后剩下的才是可以登录的。

**规则影响：**

配置Allow规则，被允许的用户账号或用户组之外的，都不允许登录；配置Deny规则，拒绝登录的用户账号或用户组将无法登录。

**检查方法：**

使用grep命令检查是否存在配置，如果无返回信息，则表示没有任何配置，否则返回配置内容：

```bash
# grep "^AllowUsers\|^AllowGroups\|^DenyUsers\|^DenyGroups" /etc/ssh/sshd_config
```

**修复方法：**

根据业务实际场景，在/etc/ssh/sshd_config文件中添加相关Allow或Deny字段，重启sshd服务，例如：

```bash
# vim /etc/ssh/sshd_config
AllowUsers root test
DenyUsers test1
# systemctl restart sshd
```
## 3.4 定时任务
### 3.4.1 确保crontab执行的脚本非属主用户不可写

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

crontab 是系统用来执行定时任务的配置文件，配置文件路径为/etc/crontab。管理员会根据实际的业务需要定义定时任务，操作系统会自动执行该任务。所以crontabs配置文件中配置的执行脚本（程序）应该只有该脚本（程序）的属主可写，不能配置其他低权限用户可写的脚本，否则其他用户可以通过修改该脚本实现提权操作。

**规则影响：**

无

**检查方法：**

检查crontabs配置文件/etc/crontab，检查执行脚本（程序）是否为其他低权限用户可写。

```bash
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
  *  *  *  *  * user-name  /bin/xxx.sh
# ll /bin/xxx.sh
-rw-------. 1 root root 451 Mar 27 17:00 /bin/xxx.sh
```

**修复方法：**

如果/etc/crontab配置文件中的执行脚本（程序）为其他低权限用户可写，则需要根据实际的业务场景进行修复：

- 修复方法1

  修改/etc/crontab配置文件中的执行脚本（程序）的文件权限，去除掉其他低特权用户的可写权限，以防止提权操作。

- 修复方法2

  修改/etc/crontab配置文件，删除该执行脚本（程序）的配置项，防止提权操作。
### 3.4.2 确保cron守护进程正常启用

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

cron 守护进程用于在系统上执行批处理作业。

即使操作系统目前可能没有需要运行的用户作业，也会有系统作业需要运行，其中就可能包括安全监控等重要作业，而 cron 守护进程就是用来执行这些作业的。cron守护进程未正常启用的影响：
1. 定时任务无法运行： 最直接的影响是配置在 cron 中的定时任务将无法自动运行。这可能会导致一些计划性的任务未能按时执行，如日志清理、备份、系统维护等。
2. 计划性任务延迟： 如果定时任务未能按时执行，可能会导致任务的延迟。这对于某些关键任务来说，可能会影响系统的正常运行和性能。
3. 系统维护和自动化受阻： 自动化任务通常用于监视系统状态、应用程序的运行情况等。如果这些任务未能按时执行，系统可能会错过对潜在问题的检测和处理。
4. 日志分析受影响： 许多系统管理员使用定时任务来执行日志分析、报告生成等任务。如果这些任务无法运行，可能会错过对系统运行情况的重要洞察。
5. 备份延误： 许多备份任务都是通过定时任务实现的。如果定时任务未运行，备份可能会受到影响，导致数据备份不及时或不完整。

**规则影响：**
无

**检查方法：**

执行以下命令来确定 cron 守护进程是否正常启用：

```bash
# systemctl is-enabled crond
enabled
```

如结果为enabled，则视为通过此项检查。

**修复方法：**

执行以下命令来启用 cron 进程：

```bash
# systemctl --now enable crond
```
### 3.4.3 确保at、cron配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

at服务用于进行简单的一次性任务执行，cron服务用于执行系统中的周期性定时任务。/etc/cron.deny是cron命令的黑名单配置文件，/etc/cron.allow是cron命令的白名单配置文件，默认不存在，白名单出现时，黑名单失效，只有root账号和写在白名单中的账号可以使用cron命令。

如果使用黑名单机制管理cron定时任务，有可能在添加了新账号之后忘记将其加入黑名单中，增大了系统潜在的安全攻击面。如果cron相关配置文件属主不为root，或者允许group和other用户访问，可能导致系统管理员以外的用户进行cron配置，带来系统安全隐患。如果系统无需启用at、cron配置，此配置项无需检查。

**规则影响：**

无

**检查方法：**

* 首先要确保系统中cron服务已经启用：

  ```bash
  # systemctl is-enabled crond
  ```

  请确认返回结果是enabled。

* 确认/etc/crontab文件和/etc/cron.hourly、/etc/cron.daily、/etc/cron.weekly、/etc/cron.monthly、/etc/cron.d目录的UID和GID都是0，且不允许group和other用户访问：  

  ```bash
  # stat /etc/crontab
  Access: (0600/-rw-------)  Uid: (    0/    root)   Gid: (    0/    root)
  ```

* 确认黑名单文件/etc/cron.deny和/etc/at.deny不存在，确认白名单文件/etc/cron.allow和/etc/at.allow设置了正确的权限，即UID和GID都是0，且不允许group和other用户访问：

  ```bash
  # stat /etc/cron.allow
  Access: (0600/-rwx------)  Uid: (    0/    root)   Gid: (    0/    root)
  ```

**修复方法：**

* 如果没有启用cron服务，使用以下命令启用：

  ```bash
  # systemctl --now enable crond
  ```

* 设置/etc/crontab文件和/etc/cron.hourly、/etc/cron.daily、/etc/cron.weekly、/etc/cron.monthly、/etc/cron.d目录的UID/GID及权限：

  ```bash
  # chown root:root /etc/crontab
  # chmod og-rwx /etc/crontab
  ```

* 删除/etc/cron.deny和/etc/at.deny文件，创建/etc/cron.allow和/etc/at.allow文件并设置正确的权限：

  ```bash
  # rm /etc/cron.deny /etc/at.deny
  # touch /etc/cron.allow /etc/at.allow
  # chmod og-rwx /etc/cron.allow
  # chmod og-rwx /etc/at.allow
  # chown root:root /etc/cron.allow
  # chown root:root /etc/at.allow
  ```
## 3.5 内核
### 3.5.1 确保内核ASLR已启用

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

ASLR通过每次将栈的起始位置、函数库和程序本身移至略微不同的位置，使得缓冲溢出攻击无法猜测正确的位置，导致攻击无法成功实施。linux内核中ASLR分为0,1,2三级通过/proc/sys/kernel/randomize_va_space文件配置查看，各级对应的效果：

0：不存在随机化，表示一切都将位于静态地址中

1：只有共享函数库、栈、mmap’ed 内存、VDSO以及堆是随机的

2：完全随机化。使用brk()进行的旧式内存配置也将是随机的

进程中栈的地址被随机化，降低缓冲溢出攻击的风险

**规则影响：**

无

**检查方法：**

输入以下命令并检查相应的命令返回是否为2：

```bash
# cat /proc/sys/kernel/randomize_va_space
2
```

**修复方法：**

修改randomize_va_space值为2：

```bash
# echo 2 > /proc/sys/kernel/randomize_va_space
```

### 3.5.2 确保dmesg访问权限配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

限制访问 dmesg 信息权限，无特权的用户无法查看系统信息，从而可以避免任何人从系统信息获取敏感信息，进而对系统进行攻击的行为。仅允许具有 CAP_SYSLOG 能力的进程查看内核日志信息。从而控制关键信息的最小权限，保障系统更加安全。

**规则影响：**

无

**检查方法：**

检查/etc/sysctl.conf文件中是否已经配置相关字段，“kernel.dmesg_restrict=1”表示已经设置dmesg的访问限制：

```bash
# grep kernel.dmesg_restrict /etc/sysctl.conf
kernel.dmesg_restrict=1
```

**修复方法：**

打开/etc/sysctl.conf文件，设置kernel.dmesg_restrict为1：

```bash
# vim /etc/sysctl.conf
kernel.dmesg_restrict=1
```
### 3.5.3 确保正确配置内核参数kptr_restrict

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

kptr_restrict的作用是保护内核符号地址，保护等级低时普通用户可以访问得到内核符号地址容易被攻击者利用，增加了攻击面降低了系统安全性。

当前kptr_restrict可以选择如下参数：

0：普通用户和带有CAP_SYSLOG特权的用户均可以读取（读取地址为内核符号地址经哈希运算后的值）。

1：只有带有CAP_SYSLOG特权的用户有读取权限（读取地址为内核符号实际地址），普通用户读取后内核符号地址打印为全零。

2：普通用户及带有CAP_SYSLOG特权的用户均无权限读取，读取后内核符号地址打印为全零。

考虑到易维护性、可定位性，openEuler发行版默认配置kptr_restrict参数为0，请根据实际场景按需配置。

**规则影响：**

普通用户无法获取内核符号地址。

**检查方法：**

输入以下命令并检查相应的命令返回值是否为1：

```bash
# sysctl kernel.kptr_restrict
kernel.kptr_restrict = 1
```

**修复方法：**

建议设置kptr_restrict的值为1：

```bash
# echo 1 > /proc/sys/kernel/kptr_restrict
```

或者修改/etc/sysctl.conf文件，添加或修改配置，并执行# sysctl –p /etc/sysctl.conf：

```bash
kernel.kptr_restrict=1
```
### 3.5.4 确保内核SMAP已启用

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

内核参数SMAP(Supervisor Mode Access Prevention，管理模式访问保护)，开启后禁止内核访问用户空间的数据。若不开启SMAP内核参数，攻击者可以利用通过内核态代码重定向的方式访问用户空间数据，增加了攻击面降低了系统安全性。

openEuler默认开启SMAP。

**规则影响：**

内核不能访问用户空间数据。

**检查方法：**

输入以下命令并检查是否有返回值，如果有返回值则说明cpu支持SMAP，反之则说明不支持SMAP：
注：仅X86架构支持SMAP特性（物理机、虚拟机均支持），其他架构可忽略该项。

```bash
# cat /proc/cpuinfo | grep "smap"
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon rep_good nopl xtopology cpuid tsc_known_freq pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch cpuid_fault invpcid_single pti tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid rdseed adx smap xsaveopt arat umip arch_capabilities
```

通过检查启动参数检验是否开启SMAP，若有返回值则说明未开启，反之则说明开启。

```bash
# cat /proc/cmdline | grep -i "nosmap"
```

**修复方法：**

若关闭了SMAP选项，需要编辑grub.cfg文件,在启动参数中删除nosmap选项。

```bash
# vim /boot/efi/EFI/openEuler/grub.cfg
```
### 3.5.5 确保内核SMEP已启用

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

内核参数SMEP(Supervisor Mode Execution Prevention，管理模式执行保护)，开启后禁止内核执行用户空间代码。若不开启SMEP内核参数，攻击者可以利用通过内核态代码重定向的方式执行用户空间代码，增加了攻击面降低了系统安全性。

openEuler默认开启SMEP。

**规则影响：**

内核不能执行用户空间代码。

**检查方法：**

输入以下命令并检查是否有返回值，如果有返回值则说明cpu支持SMEP，反之则说明不支持SMEP：
注：仅X86架构支持SMEP特性（物理机、虚拟机均支持），其他架构可忽略该项。

```bash
# cat /proc/cpuinfo | grep "smep"
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon rep_good nopl xtopology cpuid tsc_known_freq pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch cpuid_fault invpcid_single pti tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid rdseed adx smap xsaveopt arat umip arch_capabilities
```

通过检查启动参数检验是否开启SMEP，若有返回值则说明未开启，反之则说明开启。

```bash
# cat /proc/cmdline | grep -i "nosmep"
```

**修复方法：**

若关闭了SMEP选项，需要编辑grub.cfg文件,在启动参数中删除nosmep选项。

```bash
# vim /boot/efi/EFI/openEuler/grub.cfg
```
### 3.5.6 禁止系统响应ICMP广播报文

**级别：** 要求

**适用版本：** 全部

**规则说明：**

ICMP是网络控制消息协议，主要用于传递查询报文与差错报文，通过设置是否接受ICMP广播报文对ICMP报文攻击进行防护。

该参数决定设备是否要回应ICMP echo消息和时间戳请求，对这些消息和请求来说，目的地址就是广播地址。无论是哪台设备发送的报文，报文都会发送到网络上的每一台设备上去。如果源地址是伪造的，就可能会导致网络上所有的设备发送恶意的echo报文给受害者（被伪造地址的设备）。

**规则影响：**

系统不响应ICMP广播报文。

**检查方法：**

首先，检查当前系统内核参数的设置。执行以下命令并检查icmp_echo_ignore_broadcasts参数的返回值，如果icmp_echo_ignore_broadcasts参数返回值为1，表示系统禁止响应ICMP报文。如果icmp_echo_ignore_broadcasts参数返回值为0，表示系统未禁止响应ICMP报文。

```bash
# sysctl net.ipv4.icmp_echo_ignore_broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1
```

其次，执行如下命令，如果返回值不为1，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置(值为1)。

```bash
# grep "net.ipv4.icmp_echo_ignore_broadcasts" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv4.icmp_echo_ignore_broadcasts=1
```

**修复方法：**

输入命令禁止系统响应ICMP广播报文：

```bash
# sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
```

修改/etc/sysctl.conf文件，添加或修改配置

```bash
net.ipv4.icmp_echo_ignore_broadcasts=1
```
### 3.5.7 禁止接收ICMP重定向报文

**级别：** 要求

**适用版本：** 全部

**规则说明：**

ICMP重定向消息是传递路由信息并告诉系统通过备用路径发送数据包。这是一种允许外部路由设备更新系统路由表的方法。通过将net.ipv4.conf.all.accept_redirects和net.ipv6.conf.all.accept_redirects设置为0，系统不会接受任何ICMP重定向报文。通过将net.ipv4.conf.all.secure_redirects和net.ipv4.conf.default.send_redirects设置为0，系统不会从网关接收ICMP重定向报文（IPv6无此配置项）。

攻击者可以利用伪造的ICMP重定向消息恶意更改系统路由表，使它们向错误的网络发送数据包，从而获取相应的敏感数据。

**规则影响：**

系统不接收ICMP重定向报文。

**检查方法：**

首先，检查当前系统内核参数的设置。输入命令查看返回值是否为0：

```bash
# sysctl net.ipv4.conf.all.accept_redirects && sysctl net.ipv6.conf.all.accept_redirects && sysctl net.ipv4.conf.all.secure_redirects && sysctl net.ipv4.conf.default.secure_redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.seure_redirects = 0
```

其次，执行如下命令，如果返回值不为0，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置(值为0)。

```bash
# grep "net.ipv4.conf.all.accept_redirects" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv4.conf.all.accept_redirects=0
# grep "net.ipv6.conf.all.accept_redirects" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv6.conf.all.accept_redirects=0
# grep "net.ipv4.conf.all.secure_redirects" /etc/sysctl.conf /etc/sysctl.d/*
/etc/sysctl.conf:net.ipv4.conf.all.secure_redirects=0
/etc/sysctl.d/99-sysctl.conf:net.ipv4.conf.all.secure_redirects=0
# grep "net.ipv4.conf.default.secure_redirects" /etc/sysctl.conf /etc/sysctl.d/*
/etc/sysctl.conf:net.ipv4.conf.default.secure_redirects=0
/etc/sysctl.d/99-sysctl.conf:net.ipv4.conf.default.secure_redirects=0
```

**修复方法：**

输入命令禁止接收ICMP重定向报文：

```bash
# sysctl -w net.ipv4.conf.all.accept_redirects=0
# sysctl -w net.ipv6.conf.all.accept_redirects=0
# sysctl -w net.ipv4.conf.all.secure_redirects=0
# sysctl -w net.ipv4.conf.default.secure_redirects=0
```

修改/etc/sysctl.conf文件，添加或修改配置：

```bash
net.ipv4.conf.all.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
```
### 3.5.8 禁止转发ICMP重定向报文

**级别：** 要求

**适用版本：** 全部

**规则说明：**

ICMP重定向用于向其他主机发送路由信息。由于主机本身不充当路由器，因此没有必要转发ICMP重定向数据包。

攻击者可以利用受到攻击的主机向其他路由器设备发送无效的ICMP重定向，试图破坏路由，并让用户访问错误的系统。

**规则影响：**

系统不转发ICMP重定向报文。

**检查方法：**

首先，检查当前系统内核参数的设置。执行以下命令并检查send_redirects参数的返回值，如果send_redirects参数返回值为1，表示系统转发ICMP重定向报文。如果send_redirects参数返回值为0，表示系统不转发ICMP重定向报文。

```bash
# sysctl net.ipv4.conf.all.send_redirects
net.ipv4.conf.all.send_redirects = 0
# sysctl net.ipv4.conf.default.send_redirects
net.ipv4.conf.default.send_redirects = 0
```

其次，执行如下命令，如果返回值不为0，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置(值为0)。

```bash
# grep "net.ipv4.conf.all.send_redirects" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv4.conf.all.send_redirects=0
# grep "net.ipv4.conf.default.send_redirects" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv4.conf.default.send_redirects=0
```

**修复方法：**

输入命令禁止转发ICMP重定向报文：

```bash
# sysctl -w net.ipv4.conf.all.send_redirects=0
# sysctl -w net.ipv4.conf.default.send_redirects=0
# sysctl -w net.ipv4.route.flush=1
```

修改/etc/sysctl.conf文件，添加或修改配置：

```bash
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
```
### 3.5.9 应当忽略所有ICMP请求

**级别：** 建议

**适用版本：** 全部

**规则说明：**

通过忽略所有ICMP请求，禁止外界通过ping命令访问系统。

攻击者可以通过ping命令的返回来感知系统所处的网址位置。

**规则影响：**

系统忽略所有ICMP请求。

**检查方法：**

首先，检查当前系统内核参数的设置。执行以下命令并检查icmp_echo_ignore_all参数的返回值，如果icmp_echo_ignore_all参数返回值为1，表示系统忽略所有ICMP请求。如果icmp_echo_ignore_all参数返回值为0，表示系统响应ICMP请求。

```bash
# sysctl net.ipv4.icmp_echo_ignore_all
net.ipv4.icmp_echo_ignore_all = 0
```

其次，执行如下命令，如果返回值不为1，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置(值为0)，建议用户在配置文件中添加正确配置。

```bash
# grep "net.ipv4.icmp_echo_ignore_all" /etc/sysctl.conf /etc/sysctl.d/*
```

**修复方法：**

输入命令禁止转发ICMP重定向报文：

```bash
# sysctl -w net.ipv4.icmp_echo_ignore_all=1
```

修改/etc/sysctl.conf文件，添加或修改配置：

```bash
net.ipv4.icmp_echo_ignore_all=1
```
### 3.5.10 确保丢弃伪造的ICMP报文，不记录日志

**级别：** 要求

**适用版本：** 全部

**规则说明：**

将icmp_ignore_bogus_error_responses设置为1可以防止内核记录广播重复数据包的响应，从而避免文件系统填充无用的日志信息。

一些攻击者会发送违反RFC-1122的ICMP报文，并试图用大量无用的错误信息填充日志文件系统。

**规则影响：**

系统丢弃伪造的ICMP报文，不记录日志

**检查方法：**

首先，检查当前系统内核参数的设置。执行以下命令并检查icmp_ignore_bogus_error_responses参数的返回值，如果icmp_ignore_bogus_error_responses参数返回值为1，表示系统忽略ICMP错误响应。如果icmp_ignore_bogus_error_responses参数返回值为0，表示系统处理ICMP错误响应。

```bash
# sysctl net.ipv4.icmp_ignore_bogus_error_responses
net.ipv4.icmp_ignore_bogus_error_responses = 1
```

其次，执行如下命令，如果返回值不为1，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置(值为1)。

```bash
# grep "net.ipv4.icmp_ignore_bogus_error_responses" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv4.icmp_ignore_bogus_error_responses = 1
```

**修复方法：**

输入丢弃伪造的ICMP报文规则的命令：

```bash
# sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
# sysctl -w net.ipv4.route.flush=1
```

修改/etc/sysctl.conf文件，添加或修改配置：

```bash
net.ipv4.icmp_ignore_bogus_error_responses = 1
```
### 3.5.11 确保反向地址过滤已启用

**级别：** 要求

**适用版本：** 全部

**规则说明：**

将net.ipv4.conf.all.rp_filter和net.ipv4.conf.default.rp_filter设置为1，强制Linux内核对接收到的数据包使用反向路径过滤，检查报文源地址的合法性，如果反查源地址的路由表，发现源地址下一跳的最佳出接口并不是收到报文的入接口，则将报文丢弃。

攻击者可以实施IP地址欺骗，在目前网络攻击中使用比较多。通过反向地址过滤在收到数据包时，取出源IP地址，然后查看该路由器的路由表中是否有该数据包的路由信息。如果路由表中没有其用于数据返回的路由信息，那么极有可能是某人伪造了该数据包，于是路由便把它丢弃。

**规则影响：**

无

**检查方法：**

首先，检查当前系统内核参数的设置。执行以下命令，检查rp_filter参数的返回值是否为1。

```bash
# sysctl net.ipv4.conf.all.rp_filter
net.ipv4.conf.all.rp_filter = 1
# sysctl net.ipv4.conf.default.rp_filter
net.ipv4.conf.default.rp_filter = 1
```

其次，执行如下命令，如果返回值不为1，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置(值为1)。

```bash
# grep "net.ipv4.conf.all.rp_filter" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv4.conf.all.rp_filter = 1
# grep "net.ipv4.conf.default.rp_filter" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv4.conf.default.rp_filter = 1
```

**修复方法：**

输入启用反向地址过滤的命令：

```bash
# sysctl -w net.ipv4.conf.all.rp_filter=1
# sysctl -w net.ipv4.conf.default.rp_filter=1
# sysctl -w net.ipv4.route.flush=1
```

修改/etc/sysctl.conf文件，添加或修改配置：

```bash
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
```
### 3.5.12 禁止IP转发

**级别：** 要求

**适用版本：** 全部

**规则说明：**

如果该结点不作为网关服务器，则应禁用IP转发功能。否则攻击者可将此系统作为路由器使用。

对于容器场景，如果容器内部需要通过宿主机转发网络报文，则可以例外。

**规则影响：**

系统不允许IP转发

**检查方法：**

首先，检查当前系统内核参数的设置。执行以下命令并检查ip_forward参数的返回值，如果ip_forward参数返回值为0，表示禁用IP转发。如果ip_forward参数返回值为1，表示启用IP转发。

```bash
# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 0
# sysctl net.ipv6.conf.all.forwarding
net.ipv6.conf.all.forwarding = 0
```

其次，执行如下命令，如果返回值不为0，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置(值为0)。

```bash
# grep -E -s "^\s*net\.ipv4\.ip_forward\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf
无任何输出
# grep -E -s "^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf
无任何输出
```

**修复方法：**

输入禁止IP转发的命令并修改配置文件：

```bash
# grep -Els "^\s*net\.ipv4\.ip_forward\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri "s/^\s*(net\.ipv4\.ip_forward\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/" $filename; done; sysctl -w net.ipv4.ip_forward=0; sysctl -w net.ipv4.route.flush=1

# grep -Els "^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri "s/^\s*(net\.ipv6\.conf\.all\.forwarding\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/" $filename; done; sysctl -w net.ipv6.conf.all.forwarding=0; sysctl -w net.ipv6.route.flush=1
```
### 3.5.13 禁止报文源路由

**级别：** 要求

**适用版本：** 全部

**规则说明：**

在网络中，源路由允许发送方部分或全部指定数据包通过网络的路由，而常规路由中，网络中的路由器根据数据包的目的地确定路径。大量报文被篡改后通过指定路由，则可以对内部网络进行定向攻击，可导致指定路由器负载过高，正常业务流量中断。

攻击者可以伪造一些合法的IP地址，通过合适的设置源路由选项及合法的路由器，蒙混进入网络。另外，如果允许源路由数据包，则通过构造中间路由地址，可以用于访问专用地址系统；如果攻击者对原始报文截取，并利用源路由进行地址欺骗，则可以强制指定回传的报文都通过攻击者的设备进行路由返回，这样攻击者就可以成功接收到双向的数据包。所以，应禁用报文源路由，减小攻击面。

**规则影响：**

系统禁用报文源路由

**检查方法：**

输入以下命令并检查相应的命令返回，如果返回值不为0，建议修改。

```bash
# sysctl net.ipv4.conf.all.accept_source_route
net.ipv4.conf.all.accept_source_route = 0
# sysctl net.ipv4.conf.default.accept_source_route
net.ipv4.conf.default.accept_source_route = 0
# sysctl net.ipv6.conf.all.accept_source_route
net.ipv6.conf.all.accept_source_route = 0
# sysctl net.ipv6.conf.default.accept_source_route
net.ipv6.conf.default.accept_source_route = 0
```

**修复方法：**

输入禁止报文源路由的命令：

```bash
# sysctl -w net.ipv4.conf.all.accept_source_route=0
# sysctl -w net.ipv4.conf.default.accept_source_route=0
# sysctl -w net.ipv6.conf.all.accept_source_route=0
# sysctl -w net.ipv6.conf.default.accept_source_route=0
# sysctl -w net.ipv4.route.flush=1
# sysctl -w net.ipv6.route.flush=1
```

修改/etc/sysctl.conf文件，添加或修改配置：

```bash
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
```
### 3.5.14 确保TCP-SYN cookie保护已启用

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

TCP-SYN cookie保护减轻了系统在遭受SYN Flooding攻击时受到的影响。

攻击者使用SYN泛洪攻击时，快速耗尽内核中半开连接队列，阻止合法连接。但启用SYN cookie，即使受到拒绝服务攻击仍允许系统继续接受合法连接。

**规则影响：**

无

**检查方法：**

首先，检查当前系统内核参数的设置。执行以下命令并检查tcp_syncookies参数的返回值，如果tcp_syncookies参数返回值为1，表示启用TCP-SYN cookie保护机制。如果tcp_syncookies参数返回值为0，表示未启用TCP-SYN cookie保护机制。

```bash
# sysctl net.ipv4.tcp_syncookies
net.ipv4.tcp_syncookies = 1
```

其次，执行如下命令，如果返回值不为1，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置（值为1）。

```bash
# grep "^net.ipv4.tcp_syncookies" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv4.tcp_syncookies=1
/etc/sysctl.d/99-sysctl.conf:net.ipv4.tcp_syncookies=1
```

**修复方法：**

* 启用保护，可使用如下命令临时设置，重启后恢复默认值：

    ```bash
    # sysctl -w net.ipv4.tcp_syncookies=1
    # sysctl -w net.ipv4.route.flush=1
    ```

* 修改/etc/sysctl.conf文件，添加或修改配置，并执行# sysctl -p /etc/sysctl.conf，使其永久生效：
    ```bash
    net.ipv4.tcp_syncookies=1
    ```
### 3.5.15 应当记录仿冒、源路由以及重定向报文日志

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

记录欺骗的包、源路由包和发给系统的重定向包有助于发现攻击源与制定防护措施。

**规则影响：**

开启后会记录带有不允许的地址的数据到内核日志中，存在冲日志风险。

**检查方法：**

首先，检查当前系统内核参数的设置。执行以下命令并检查log_martians参数的返回值，如果log_martians参数返回值为1，表示开启记录仿冒、源路由以及重定向报文日志。如果log_martians参数返回值为0，表示系统关闭记录机制。

```bash
# sysctl net.ipv4.conf.all.log_martians
net.ipv4.conf.all.log_martians = 0
# sysctl net.ipv4.conf.default.log_martians
net.ipv4.conf.default.log_martians = 0
```

其次，执行如下命令，如果返回值不为1，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置（值为0），建议用户在配置文件中添加正确配置。

```bash
# grep "^net.ipv4.conf.all.log_martians" /etc/sysctl.conf /etc/sysctl.d/*
# grep "^net.ipv4.conf.default.log_martians" /etc/sysctl.conf /etc/sysctl.d/*
```

**修复方法：**

* 打开记录，可使用如下命令临时设置，重启后恢复默认值：

    ```bash
    # sysctl -w net.ipv4.conf.all.log_martians=1
    # sysctl -w net.ipv4.conf.default.log_martians=1
    ```

* 修改/etc/sysctl.conf文件，添加或修改配置，并执行# sysctl -p /etc/sysctl.conf，使其永久生效：

    ```bash
    net.ipv4.conf.all.log_martians=1
    net.ipv4.conf.default.log_martians=1
    ```
### 3.5.16 避免开启tcp_timestamps

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

tcp_timestamps用于记录TCP数据包的发送时间，可用于RTT测量（RTTM）和保护序号绕回（PAWS），是一个双向的选项，只有在客户端和服务端同时启用时才使能。启用该选项可能遭受拒绝服务攻击。

**规则影响：**

关闭此项会影响TCP在极端情况下超时重传的可靠性。

**检查方法：**

首先，检查当前系统内核参数的设置，执行以下命令并检查tcp_timestamps参数的返回值，如果tcp_timestamps参数返回值为1，表示开启tcp_timestamps机制。如果参数返回值为0，表示关闭tcp_timestamps机制。

```bash
# sysctl net.ipv4.tcp_timestamps
net.ipv4.tcp_timestamps = 1
```

其次，执行如下命令，如果返回值不为0，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置（默认值为1），建议用户在配置文件中添加正确配置。

```bash
# grep "^net.ipv4.tcp_timestamps" /etc/sysctl.conf /etc/sysctl.d/*
```

**修复方法：**

* 关闭tcp_timestamps，可使用如下命令临时设置，重启后恢复默认值：

    ```bash
    # sysctl -w net.ipv4.tcp_timestamps=0
    ```

* 修改/etc/sysctl.conf文件，添加或修改配置，并执行# sysctl -p /etc/sysctl.conf，使其永久生效：

    ```bash
    net.ipv4.tcp_timestamps=0
    ```
### 3.5.17 确保TIME_WAIT TCP协议等待时间已配置

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

TIME_WAIT是TCP协议等待连接销毁的时间，设置过长会导致存在大量未关闭的TCP连接，导致遭受拒绝服务攻击，建议配置不大于60。

**规则影响：**

TIME_WAIT时间设置过长会导致遭受拒绝服务攻击

**检查方法：**

首先，检查当前系统内核中TIME_WAIT值的设置，执行以下命令并检查tcp_fin_timeout参数的返回值。

```bash
# sysctl net.ipv4.tcp_fin_timeout
net.ipv4.tcp_fin_timeout = 60
```
其次，执行如下命令，如果返回值与内核参数不一致，建议根据需求进行修改。如果返回值为空，表示系统使用默认配置（默认值为60）。

```bash
# grep "^net.ipv4.tcp_fin_timeout" /etc/sysctl.conf /etc/sysctl.d/*
```

**修复方法：**

* 设置TIME_WAIT tcp协议等待时间，建议不大于60，可使用如下命令临时设置，重启后恢复默认值：

    ```bash
    # sysctl -w net.ipv4.tcp_fin_timeout=60
    ```

* 修改/etc/sysctl.conf文件，添加或修改配置，并执行# sysctl -p /etc/sysctl.conf，使其永久生效：

    ```bash
    net.ipv4.tcp_fin_timeout=60
    ```
### 3.5.18 应当正确配置SYN_RECV状态队列数量

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

SYN_RECV队列保存尚未获得对方确认的TCP连接请求，值越大表示可以容纳更多等待连接的网络连接数。如果配置值太小，容易被TCP SYN泛洪攻击，导致正常连接被拒绝服务；配置太大，则会消耗更多系统资源。建议队列数量设置为256。

**规则影响：**

从安全角度，建议配置较大值以消减TCP SYN泛洪攻击，但配置太大，则会消耗更多系统资源，对内存较小环境，可能会影响正常业务。

**检查方法：**

首先，检查当前系统内核中SYN_RECV队列数量的设置，执行以下命令并检查tcp_fin_timeout参数的返回值。

```bash
# sysctl net.ipv4.tcp_max_syn_backlog
net.ipv4.tcp_max_syn_backlog = 256
```

其次，执行如下命令，如果返回值与内核参数不一致，建议根据需求进行修改。如果返回值为空，表示系统使用默认配置（默认值为256）。

```bash
# grep "^net.ipv4.tcp_max_syn_backlog" /etc/sysctl.conf /etc/sysctl.d/*
net.ipv4.tcp_max_syn_backlog=256
```

**修复方法：**

* 设置SYN_RECV状态队列数量，可使用如下命令临时设置，重启后恢复默认值：

    ```bash
    # sysctl -w net.ipv4.tcp_max_syn_backlog=256
    ```

* 修改/etc/sysctl.conf文件，添加或修改配置，并执行# sysctl -p /etc/sysctl.conf，使其永久生效：

    ```bash
    net.ipv4.tcp_max_syn_backlog=256
    ```
### 3.5.19 禁止使用ARP代理

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

ARP代理允许系统代表连接到某个接口的主机向另一个接口上的ARP请求发送响应。禁用ARP代理不仅可以防止未经授权的信息共享还可以防止连接的网络区段之间寻址信息泄露。所以应关闭ARP代理以避免ARP报文攻击对系统造成影响。

openEuler默认禁止使用ARP代理，用户可根据业务需求进行配置。

**规则影响：**

依赖于ARP代理的程序执行受限制

**检查方法：**

首先，检查当前系统内核参数的设置，执行以下命令并检查proxy_arp参数的返回值，如果proxy_arp参数返回值为1，表示开启ARP代理。如果proxy_arp参数返回值为0，表示禁止使用ARP代理。

```bash
# sysctl net.ipv4.conf.all.proxy_arp
net.ipv4.conf.all.proxy_arp = 0
# sysctl net.ipv4.conf.default.proxy_arp
net.ipv4.conf.default.proxy_arp = 0
```

其次，执行如下命令，如果返回值不为0，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置（值为0）。

```bash
# grep "^net.ipv4.conf.all.proxy_arp" /etc/sysctl.conf /etc/sysctl.d/*
# grep "^net.ipv4.conf.default.proxy_arp" /etc/sysctl.conf /etc/sysctl.d/*
```
**修复方法：**

* 关闭ARP代理的命令，可使用如下命令临时设置，重启后恢复默认值：

    ```bash
    # sysctl -w net.ipv4.conf.all.proxy_arp=0
    # sysctl -w net.ipv4.conf.default.proxy_arp=0
    ```

* 修改/etc/sysctl.conf文件，添加或修改配置，并执行# sysctl -p /etc/sysctl.conf，使其永久生效：

    ```bash
    net.ipv4.conf.all.proxy_arp=0
    net.ipv4.conf.default.proxy_arp=0
    ```
### 3.5.20 确保core dump配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

Core dump是当程序运行过程中异常终止或崩溃时，把内存状态记录下来的行为，有助于事后定位，但可能会包含进程内存里的敏感信息。有时用户需要开启core dump功能记录当时产生问题的原因，对于需要开启core dump功能的用户需对日志输入的路径进行限制，同时需限制路径只允许特定用户访问。

启用core dump有助于程序异常终止或崩溃的事后定位，但容易泄露内存中的敏感信息。openEuler默认打开，用户需要根据业务场景，关闭core dump或对日志输入的路径和访问用户进行限制。

**规则影响：**

关闭core dump后，程序异常时缺少日志记录，不利于问题定位。

**检查方法：**

* 禁用场景的检查方法：

  输入以下命令并检查相应的命令返回：

  ```bash
  # ulimit -c
  0
  ```

  或者检查文件/etc/security/limits.conf，是否包含配置行“* hard core 0”。

* 限制场景的检查方法：

  执行以下脚本成功返回（无内容输出），表示已限制了core dump目录：
  
  ```bash
  #!/bin/bash  
  core_path=$(sysctl kernel.core_pattern | awk -F"^[[:space:]]*kernel.core_pattern[[:space:]]*=[[:space:]]*" '{print $2}')
  [[ "${core_path}" =~ ^/.+ ]] || { echo "kernel.core_pattern[${core_path}] must be started with /"; exit 1; }
  core_dir=$(dirname "${core_path}")
  [[ -d "${core_dir}" ]] || { echo "kernel.core_pattern dir[${core_dir}] not exist"; exit 1; }
  rights_digit=$(stat -c%a "${core_dir}")
  [[ "${rights_digit}" =~ ^700$ || "${rights_digit}" =~ ^1770$ || "${rights_digit}" =~ ^1777$ ]] || { echo "rights[${rights_digit}] of dir[${core_dir}] not safe, must be 700 or 1770 or 1777"; exit 1; }
  exit 0
  ```

**修复方法：**

* 禁用方法

  使用如下命令对当前会话禁止系统支持生成core dump
  ```bash
  # ulimit -c 0
  ```

  修改/etc/security/limits.conf文件，添加或修改配置，使其永久生效
  ```bash
  * hard core 0
  ```

* 限制使用方法：
  1、ulimit -c不为0，比如：
  
    ```bash
    # ulimit -c 10485760
    ```
  
  2、设置core dump日志文件保存位置和文件格式
    通过修改/proc/sys/kernel/core_pattern可以控制core dump日志文件保存位置和文件格式。
    下例为将所有的core dump日志文件生成到/corefiles目录下（绝对路径），文件名的格式为core-命令名-pid-时间戳：
  
    ```bash
    # sysctl "kernel.core_pattern=/corefiles/core-%e-%p-%t"
    ```
  
    修改/etc/sysctl.conf文件，添加或修改配置
    ```bash
    kernel.core_pattern=/corefiles/core-%e-%p-%t
    ```
  
    建议为/corefiles建立独立分区，禁止/corefiles目录占用系统分区或业务分区，避免因为core dump日志文件过多导致分区满而影响系统运行或业务运行。
  
  3、限制目录访问权限：
    可根据业务需要限制目录的访问用户范围。
    a、限制单个用户（比如admin）访问
  
    ```bash
    # chown admin /corefiles
    # chmod 700 /corefiles
    ```
  
    b、使用粘滞位保护技术，限制同组用户（比如core_group）访问
  
    ```bash
    # chown root:core_group /corefiles
    # chmod 1770 /corefiles
    ```
  
    c、使用粘滞位保护技术，限制所有用户访问：
  
    ```bash
    # chown root:root /corefiles
    # chmod 1777 /corefiles
    ```
  
    注：粘滞位对目录的作用，使得目录下A用户不能访问B用户的文件，除非B用户的文件权限允许A用户访问。
  
  4、建议禁止setuid的应用支持生成core dump：
    使用如下命令对当前运行系统禁止setuid的应用支持生成core dump
    ```bash
    # sysctl -w "fs.suid_dumpable=0"
    ```
  
    修改/etc/sysctl.conf文件，添加或修改配置，使其永久生效
    ```bash
    fs.suid_dumpable=0
    ```
### 3.5.21 禁止使用SysRq键

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

SysRq使得具有物理访问的用户能够访问计算机中危险的系统级命令，需要对SysRq的功能使用进行限制。

如果没有禁用SysRq键，则可以通过键盘触发SysRq的调用，可能造成直接发送命令到内核，对系统造成影响。

openEuler默认禁止使用SysRq键。

**规则影响：**

系统下sysRq相关命令无法使用

**检查方法：**

首先，检查当前系统内核参数的设置。执行以下命令，如果sysrq参数返回值为0，表示禁用SysRq键。否则，表示配置不正确，建议修改配置文件内容。

```bash
# cat /proc/sys/kernel/sysrq
0
```

其次，执行如下命令，如果返回值不为0，表示配置不正确，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置（值为0）。

```bash
# grep "^kernel.sysrq" /etc/sysctl.conf /etc/sysctl.d/*
/etc/sysctl.conf:kernel.sysrq=0
/etc/sysctl.d/99-sysctl.conf:kernel.sysrq=0
```

**修复方法：**

* 禁用SysRq，可使用如下命令临时设置，重启后恢复默认值：

    ```bash
    # echo 0 > /proc/sys/kernel/sysrq
    ```
    或
    ```bash
    # sysctl -w kernel.sysrq=0
    ```

* 修改/etc/sysctl.conf文件，添加或修改配置，并执行# sysctl -p /etc/sysctl.conf，使其永久生效：

    ```bash
    kernel.sysrq=0
    ```
### 3.5.22 应当正确配置内核参数ptrace_scope

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

ptrace是一种系统调用用于进程跟踪，提供了父进程可以观察并控制子进程的能力。Linux Kernel 3.4以及更高版本支持完全限制或禁用ptrace功能，根据Linux Kernel Yama Documentation，ptrace_scope可以选择如下参数：

0：进程可以将PTRACE_ATTACH传递给任何其他进程，只要它是可转储的（即没有转换uid，没有特权启动或没有调用prctl）。

1：进程如果要调用PTRACE_ATTACH，必须有预先的定义关系。默认情况下满足上述条件时，预定义的关系仅为子进程的关系。若要改变关系，子进程可以调用prctl调整这种关系。

2：只有具有CAP_SYS_PTRACE的进程通过PTRACE_ATTACH或通过子进程调用PTRACE_TRACEME才能使用ptrace。

3：任何进程都不能将ptrace与PTRACE_ATTACH一起使用，也不能通过PTRACE_TRACEME使用。

openEuler默认参数为0，用户可根据实际使用场景进行配置，建议配置值为2。

**规则影响：**

该参数的配置将影响ptrace的使用，当配置参数为2时，只有CAP_SYS_PTRACE的进程才能使用ptrace，这样会有效防止攻击者恶意提权，但同时会导致用户ptrace部分功能受到影响。

**检查方法：**

首先，检查当前系统内核参数的设置，执行以下命令并检查log_martians参数的返回值与业务场景需求是否一致。

```bash
# sysctl kernel.yama.ptrace_scope
kernel.yama.ptrace_scope = 0
```

其次，执行如下命令，如果返回值不为2，建议修改配置文件内容。如果返回值为空，表示系统使用默认配置（值为0），建议用户在配置文件中添加正确配置。

```bash
# grep "^kernel.yama.ptrace_scope" /etc/sysctl.conf /etc/sysctl.d/*
```

**修复方法：**

* 设置ptrace_scope的值，可使用如下命令临时设置，重启后恢复默认值：

    ```bash
    # echo 2 > /proc/sys/kernel/yama/ptrace_scope
    ```
    或
    ```bash
    # sysctl -w kernel.randomize_va_space=2
    ```

* 修改/etc/sysctl.conf文件，添加或修改配置，并执行# sysctl -p /etc/sysctl.conf，使其永久生效：

    ```bash
    kernel.yama.ptrace_scope=2
    ```
### 3.5.23 应当启用seccomp

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

seccomp（全称：secure computing mode），在刚引入linux内核时，将进程可用的系统调用限制为四种：read，write，_exit，sigreturn。最初的这种白名单方式，除了已打开的文件描述符允许的四种系统调用，如果尝试其他系统调用，内核就会使用SIGKILL或SIGSYS终止该进程。

白名单方式由于限制太强，实际作用并不大，在实际应用中需要更加精细的限制，为了解决此问题，引入了BPF。seccomp和BPF规则的结合，它允许用户使用可配置的策略过滤系统调用，该策略使用Berkeley Packet Filter规则实现，它可以对任意系统调用及其参数进行过滤。

openEuler内核默认已经提供seccomp功能支持，同时提供了libseccomp外围包，帮助用户态程序可以方便的设置seccomp规则。

**规则影响：**

seccomp并不能全局设置启闭或规则，而是针对于每一个进程的，也就是进程可以自己设置启用seccomp，作用于自身以及所有子线程，但不影响其他进程。

如果进程启用了seccomp，在进行系统调用时会有性能损失，用户需要根据实际业务场景确定性能损失是否可接受。

**检查方法：**

检查目标进程是否启用了seccomp模式，此处以检查test_seccomp进程为例，首先确定进程号：
```bash
# ps -aux | grep "test_seccomp" 
root  [PID_num]  0.0  0.0   2688   976 pts/0    S    12:35   0:00 ./test_seccomp
```

根据获取的pid号查询进程是否启用了seccomp功能，若返回值为0代表未开启seccomp功能，1代表开启seccomp STRICT模式，2则代表该进程启用了seccomp FILTER模式。如果用户需要开启seccomp FILTER模式，则建议用户根据实际业务场景设置合理的规则：

```bash
# cat /proc/[pid]/status | grep "Seccomp"
Seccomp:        2
```

**修复方法：**

可以在业务进程中通过调用libseccomp接口进行seccomp相关规则的配置，具体配置方法，可以参考libseccomp的开源帮助文档。

## 3.6 时间同步
### 3.6.1 应当正确配置ntpd服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

集群场景下，服务器时间是否准确、是否一致比较关键。例如当时间不一致时，可能会导致不同服务器间产生的数据，在根据时间进行排序或比较时，产生的结果不准确。

即使我们在初始时使用date命令把所有服务器时间配置成一致的，随着时间的推移，服务器的时间还是会出现不准确、不一致。所以为保证环境中所有机器的时间同步且准确，必须有一个可以同步的时间服务器，网络内的其他服务器都向该服务器进行时间同步。

当使用ntpd服务实现时间同步时，如果没有正确配置ntpd服务，则服务器时间可能不准确，导致不同服务器间的时间可能不一致。

服务器时间不准确时，对于类似财务、订单等时间敏感的数据会有很大问题。例如因为时间不准确可能导致一笔记账数据落在了错误的财务周期，从而导致资产负债表期末余额不平。

服务器之间的时间不一致时，每个主机产生的报文的时间就存在偏差，如果多个服务器间数据流存在一定处理顺序，后一个环节的服务器时间小于前一个服务器的时间时，可能会导致收到的报文因为时间大于本地时间而丢弃。

**规则影响：**

无

**检查方法：**

- 检查ntpd服务是否启动，Active字段返回“active (running)”表示服务已经启动，返回“inactive (dead)”表示未启动：

  ```bash
  # service ntpd status 2>&1 | grep Active
     Active: inactive (dead)
  ```

- 通过grep命令查看/etc/ntp.conf中restrict的配置，获取ntp权限控制配置：

  ```bash
  # grep "^restrict" /etc/ntp.conf 
  restrict default nomodify notrap nopeer noquery
  ```

- 通过grep命令查看/etc/ntp.conf中server|pool的配置（<IP or domain name>表示具体的服务器IP或域名），获取ntp服务器配置：

  ```bash
  # grep -E "^(server|pool)" /etc/ntp.conf
  server <IP or domain name> iburst
  ```

**修复方法：**

- 将本机配置为时间源，在/etc/ntp.conf文件中增加ntp权限控制配置：

  ```bash
  # vim /etc/ntp.conf 
  restrict <IP or netmask_IP> <parameter>
  ```

  - IP or netmask_IP：权限控制的IP地址，可以是default表示所有IP；可以是不带mask的某一个具体IP地址，例如“192.168.1.2”；也可以是IP+mask表示某一段IP地址，例如“192.168.0.0 mask 255.255.255.0”，表示192.168.0.1至192.168.0.154的所有地址的服务器都可以连接本服务器获取ntp服务。
  - Parameter：权限控制的具体参数。

  例如：restrict default nomodify notrap nopeer noquery，表示允许所有IP地址的服务器与本机时间源进行时间同步，但不允许在此系统上查询或修改服务。

- 本机作为客户端，配置时间源服务器（remote-server为远端时间源服务器地址），在/etc/ntp.conf文件中增加配置：

  ```bash
  # vim /etc/ntp.conf 
  server <remote-server>
  ```

- 在进行前两项配置后（可以同时配置，既作为客户端从远端服务器获取授时，也作为服务端，给其他服务器授时），使用service ntpd restart命令重启ntpd服务：

  ```bash
  # service ntpd restart
  ```
### 3.6.2 应当正确配置chronyd服务

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

授时服务器配置不正确，可能导致本地服务器时间同周边其他服务器不同步，同标准时间不同步，对于一些强依赖于时间同步的服务，如市场交易等，可能造成业务中断、错误，甚至被攻击者利用时间差进行数据篡改、伪造。

chrony是一个开源的自由软件，同传统NTP服务一样，它能保持系统时钟与授时服务器同步，让时间保持精确，由两个程序组成：chronyd和chronyc。

chronyd是一个后台运行的守护进程，用于调整内核中运行的系统时钟和授时服务器同步，它确定计算机增减时间的比率，并对此进行补偿。

chronyc提供了一个用户界面，用于监控性能并进行多样化的配置，它可以在运行chronyd服务的计算机上工作，也可以在一台不同的远程计算机上工作。

如果根据业务场景选择使用chronyd作为时间同步服务，需正确配置远端授时服务器并启用chronyd服务。

chrony同NTP可互相替换，openEuler默认启用chronyd服务。

**规则影响：**

无

**检查方法：**

- 使用grep命令查看/etc/chrony.conf文件中是否正确配置了授时服务器地址：

  ```bash
  # grep "^server\|^pool" /etc/chrony.conf
  server <IP address>
  pool <IP address>
  ```

- 使用ps命令查看是否已启动chronyd服务，如果返回“/usr/sbin/chronyd”进程，表示已经启动：

  ```bash
  # ps -ef | grep chronyd
  chrony   1569550       1  0 18:39 ?        00:00:00 /usr/sbin/chronyd
  ```

**修复方法：**

- 修改/etc/chrony.conf文件，在pool或server字段添加正确的授时服务器地址，如果有多个授时服务器，可以按照优先顺序配置多条：

  ```bash
  # vim /etc/chrony.conf
  server <IP address>
  server <IP address>
  ```

- 使用service命令启动chronyd服务，并查看服务启动状态：

  ```bash
  # service chronyd start
  Redirecting to /bin/systemctl start chronyd.service
  # service chronyd status 2>&1 | grep Active
     Active: active (running) since Tue 2020-12-01 14:47:49 CST; 1min 6s ago
  ```
## 4 日志审计
## 4.1 Audit
### 4.1.1 确保auditd审计已启用

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

auditd组件是Linux审计框架的用户空间组件，auditd组件提供了auditctl、ausearch、aureport三个程序完成审计和查看日志功能。配置审计规则是通过auditctl程序完成的，该程序启动时从/etc/audit/audit.rules读取这些规则。后台程序本身可以通过设置/etc/audit/auditd.conf 文件来进行定制。其他两个组件分别是audispd和autrace。audispd用于给其他应用发送事件通知，而autrace则通过与strace类似的方式对系统调用进行追踪。系统中一些文件是非常重要的，是不可以轻意修改的，对于这类文件使用auditd组件对其进行审计是非常有必要的。

openEuler默认要求启用audit审计功能。

**规则影响：** 

审计系统提供了一种记录系统安全信息的方法，为系统管理员在用户违反系统规则时提供及时的警告信息，但启用后对性能有一定影响。

**检查方法：**

执行如下命令，查看auditd.service服务默认状态是否为enable

```bash
# systemctl is-enabled auditd.service
enabled
```
执行如下命令，查看auditd.service服务当前是否已经启动
```bash
# systemctl status auditd.service | grep active
Active: active (running) since Fri 2023-10-13 08:00:00 CST; 2 days ago
```
**修复方法：**

使能并启动auditd.service：

```bash
# systemctl enable auditd.service
# systemctl start auditd.service
```
### 4.1.2 确保审计日志rotate已启用

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

max_log_file_action用于配置日志文件到达大小上限时该如何处理，openEuler默认配置ROTATE，表示单个文件写满后会重新创建日志文件进行记录，不会删除原先的日志文件。

num_logs表示基于ROTATE机制，最多可以创建多少个日志文件，如果日志文件数量达到上限，则会依次覆盖最早创建的文件。openEuler默认配置为5。

num_logs取值范围为0~99，其中0和1表示不做rotate。

max_log_file_action一共有5种可选配置项：

IGNORE：表示忽略日志文件大小上限，继续在该文件上记录日志。

SYSLOG：同IGNORE类似，只是达到上限时会记录一条syslog日志。

SUSPEND：达到日志文件大小上限，auditd服务进程停止日志记录。

ROTATE：达到日志文件大小上限，新建日志文件继续记录，如果文件数达到num_logs，则覆盖旧文件。

KEEP_LOGS：同ROTATE类似，只是不受num_logs限制，会一直新建文件。

**规则影响：**

rotate会按照配置，在日志文件达到写入上限之后依次覆盖最早创建的文件。

**检查方法：**

使用如下命令检查当前配置：

```bash
# grep -iE "max_log_file_action|num_logs" /etc/audit/auditd.conf
num_logs = 5
max_log_file_action = ROTATE
```

**修复方法：**

修改/etc/audit/auditd.conf文件中max_log_file_action和num_logs字段的值：

```bash
# vim /etc/audit/auditd.conf
num_logs = <file numbers>
max_log_file_action = <action type>
```

重启auditd服务，使配置生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.3 应当配置登录审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

用户成功登录时会在/var/log/lastlog文件中刷新记录，所以只要对该文件进行审计监控，就可以记录用户登录事件。如果不配置登录审计，管理员无法从audit日志中追溯登录事件。

openEuler默认不配置登录审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置登录审计，由于在文件操作时需要记录审计日志，对性能有轻微影响，但由于登录动作本身不应快速、频繁发生，用户无感知。

**检查方法：**

通过执行如下指令，检查用户登录的审计规则：

```bash
# auditctl -l | grep -iE "lastlog"
-w /var/log/lastlog -p wa -k logins
```

**修复方法：**

在/etc/audit/rules.d/目录下新建规则文件，例如logins.rules，在文件中添加审计规则：

```bash
# vim /etc/audit/rules.d/logins.rules
-w /var/log/lastlog -p wa -k <rules name>
```

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.4 应当配置账号信息修改审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

通常情况下，业务部署完成后，用户账号、用户组已经固定，不会变更，口令由于有效期的缘故，会定期修改，但也不频繁。建议对这些认证授权关键数据进行审计监控，如果有变更，事后也可进行追溯。修改账号、用户组、口令等行为，在攻击行为中比较常见，建议配置审计规则，以便事后追溯。

openEuler默认不配置账号信息修改审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置审计，由于在操作对应配置文件时需要进行审计日志记录，对性能有轻微影响，但对用户账号、用户组以及口令的修改应不频繁，实际对用户无感知。

**检查方法：**

通过如下命令，检查修改账号信息的审计规则：

```bash
# auditctl -l | grep -iE "passwd|group|shadow"
-w /etc/group -p wa -k usermgn
-w /etc/passwd -p wa -k usermgn
-w /etc/gshadow -p wa -k usermgn
-w /etc/shadow -p wa -k usermgn
-w /etc/security/opasswd -p wa -k usermgn
```

**修复方法：**

在/etc/audit/rules.d/目录下新建规则文件，例如usermgn.rules，在文件中添加审计规则：

```bash
# vim /etc/audit/rules.d/usermgn.rules
-w /etc/group -p wa -k <rules name>
-w /etc/passwd -p wa -k <rules name>
-w /etc/gshadow -p wa -k <rules name>
-w /etc/shadow -p wa -k <rules name>
-w /etc/security/opasswd -p wa -k <rules name>
```

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.5 应当配置提权命令审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

普通用户通过调用提权命令（设置了SUID/SGID）可以获得超级管理员权限，所以提权命令的使用具有较高风险，往往被攻击者利用用于对系统进行攻击行为。

建议对提权命令进行审计监控，以便事后追溯。

openEuler默认不配置提权命令审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置审计，由于在使用提权命令时需要进行审计日志记录，对性能有轻微影响，如果用户业务存在大量、频繁调用提权命令的场景，则可能存在累积效果。

**检查方法：**

使用如下脚本检查提权命令的审计规则：

```bash
#!/bin/bash

array=`find / -xdev -type f \( -perm -4000 -o -perm -2000 \) | awk '{print $1}'`

for element in ${array[@]}
do
    ret=`auditctl -l | grep "$element "`
    if [ $? -ne 0 ]; then
        echo "$element not set"
    else
        echo $ret
    fi
done
```

如果系统中提权命令已经配置audit策略，则该脚本执行后打印出对应策略行，如果未配置，则打印出“\<file path> not set”字样，如下：

```bash
# sh check.sh
/root/test.sh not set
-a always,exit -S all -F path=/usr/bin/write -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/gpasswd -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/passwd -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/pkexec -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/crontab -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/newgrp -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/chage -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/fusermount -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/at -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/newgidmap -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/wall -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/umount -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/newuidmap -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/mount -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/bin/su -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/libexec/openssh/ssh-keysign -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/libexec/dbus-1/dbus-daemon-launch-helper -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/libexec/utempter/utempter -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/lib/polkit-1/polkit-agent-helper-1 -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/sbin/pam_timestamp_check -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/sbin/grub2-set-bootflag -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/sbin/mount.nfs -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
-a always,exit -S all -F path=/usr/sbin/unix_chkpwd -F perm=x -F auid>=1000 -F auid!=-1 -F key=privileged
```

**修复方法：**

通过如下方法，查找系统中所有可提权（SUID/SGID）命令，并按照配置格式输出到/etc/audit/rules.d/privileged.rules文件中，此处\<min uid>是/etc/login.defs文件中UID_MIN的值，openEuler上可设置为1000：

```bash
# find / -xdev -type f \( -perm -4000 -o -perm -2000 \) | awk '{print "-a always,exit -F path=" $1 " -F perm=x -F auid>=<min uid> -F auid!=unset -k <rules name>" }' > /etc/audit/rules.d/privileged.rules
```

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.6 应当配置内核模块变更审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

通常情况下，业务部署完成后，内核模块挂载已经固定，不会变更。如果发生变更，可能存在攻击行为，建议对内核模块变更进行审计监控，事后也可进行追溯。

openEuler默认不配置内核模块变更审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置审计，由于在内核模块挂载、卸载时需要进行审计日志记录，对性能有轻微影响，但内核模块挂载、卸载相关操作应不频繁，实际对用户无感知。

**检查方法：**

如果是32位系统，通过如下命令检查内核模块变更的审计规则：

```bash
# auditctl -l | grep -iE "insmod|rmmod|modprobe|init_module|delete_module"
-w /sbin/insmod -p x -k module
-w /sbin/rmmod -p x -k module
-w /sbin/modprobe -p x -k module
-a always,exit -F arch=b32 -S init_module,delete_module -F key=module
```
如果是64位系统，还需有如下配置：

```bash
-a always,exit -F arch=b64 -S init_module,delete_module -F key=module
```

**修复方法：**

如果是32位系统，在/etc/audit/rules.d/目录下新建规则文件，例如module.rules，在文件中添加审计规则：

```bash
# vim /etc/audit/rules.d/module.rules
-w /sbin/insmod -p x -k <rules name>
-w /sbin/rmmod -p x -k <rules name>
-w /sbin/modprobe -p x -k <rules name>
-a always,exit -F arch=b32 -S init_module -S delete_module -k <rules name>

```
如果是64位系统，需要再添加arch=b64相关配置：
```bash
-a always,exit -F arch=b64 -S init_module -S delete_module -k <rules name>
```
考虑兼容性，64位系统中arch=b32相关配置必须保留。 

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```

### 4.1.7 应当配置管理员特权操作审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

openEuler系统中sudo提取命令操作日志默认记录在/var/log/secure日志文件中，该文件中还记录有其他认证相关的安全日志，如果用户希望对sudo提取命令进行audit审计，建议将sudo相关日志单独记录，输出到/var/log/sudo.log中，然后再对sudo日志文件进行审计监控。sudo提权属于高危操作，在攻击行为中比较常见，建议配置审计规则，以便事后追溯。

openEuler默认不配置管理员特权操作审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置审计，由于在进行任何sudo提权操作时都需要进行审计日志记录，对性能有轻微影响，如果用户业务场景中存在大量、频繁的sudo操作，对性能影响有累积效果。

**检查方法：**

通过如下命令检查管理员特权操作的审计规则，其中sudo输出日志路径根据实际配置情况可能有变化：

```bash
# auditctl -l | grep -iE "sudo\.log"
-w /var/log/sudo.log -p wa -k sudoaction
```

**修复方法：**

修改/etc/sudoers文件，配置sudo日志独立记录到/var/log/sudo.log文件中：

```bash
vim /etc/sudoers
Defaults logfile=/var/log/sudo.log
```

在/etc/audit/rules.d/目录下新建规则文件，例如sudoaction.rules，在文件中添加审计规则，此处审计的文件“/var/log/sudo.log”必须是/etc/sudoers中配置的日志输出文件：

```bash
vim /etc/audit/rules.d/sudoaction.rules
-w /var/log/sudo.log -p wa -k <rules name>
```

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.8 应当在启动阶段启用auditd

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

在启动阶段启用auditd，可以对操作系统启动过程中，auditd服务完成启动前的事件进行审计。启动过程中如果不启用审计，如果攻击者在启动过程中添加一些攻击行为，可能就无法被审计到。

openEuler默认不配置，建议用户可根据实际场景，确定是否在内核启动参数中添加“audit=1”字段，以便在操作系统启动阶段使能审计功能。

**规则影响：**

无

**检查方法：**

执行如下命令，查看内核启动参数中是否已经添加“audit=1”：

```bash
# cat /proc/cmdline | grep "audit=1"
BOOT_IMAGE=/vmlinuz-<kernel version> root=/dev/mapper/openeuler-root ro resume=/dev/mapper/openeuler-swap rd.lvm.lv=openeuler/root rd.lvm.lv=openeuler/swap crashkernel=512M quiet audit=1 
```

**修复方法：**

* 修改grub.cfg文件，直接在对应内核启动参数后面添加，需要注意的是，grub.cfg文件所在目录根据系统安装配置会有不同，大部分情况存在于/boot/grub2/或/boot/efi/EFI/openeuler/目录下：

  ```bash
  # vim /boot/efi/EFI/openeuler/grub.cfg
  linuxefi	/vmlinuz-<kernel version> root=/dev/mapper/openeuler-root ro resume=/dev/mapper/openeuler-swap rd.lvm.lv=openeuler/root rd.lvm.lv=openeuler/swap crashkernel=512M quiet audit=1
  ```

* 或者修改配置文件/etc/default/grub，在GRUB_CMDLINE_LINUX字段添加“audit=1”，然后重新生成grub.cfg文件：

  ```bash
  # vim /etc/default/grub
  GRUB_CMDLINE_LINUX="/dev/mapper/openeuler-swap rd.lvm=openeuler/root rd.lvm.lv=openeuler/swap crashkernel quiet audit=1"
  
  # grub2-mkconfig -o /boot/grub2/grub.cfg
  ```

* 修改后重启系统生效：

  ```bash
  # reboot
  ```
### 4.1.9 应当正确配置audit_backlog_limit

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

audit_backlog_limit用于限制audit事件在发往auditd服务进行处理之前在内核中的缓存队列的大小，该值默认为64，如果队列满，则开始丢弃audit事件，并打印告警日志，提示队列满。如果该值配置过小，则可能导致audit事件丢失。

如果在操作系统启动阶段已经配置了启用auditd，则建议将audit_backlog_limit适当配置为较大值，因为内核启动过程中auditd服务尚未启动，此时所有事件都是通过队列缓存的。

openEuler默认不配置，建议用户根据实际场景，设置audit_backlog_limit参数的大小。

**规则影响：**

无

**检查方法：**

执行如下命令，查看内核启动参数中是否已经添加“audit_backlog_limit=\<size\>”：

```bash
# cat /proc/cmdline | grep "audit_backlog_limit"
BOOT_IMAGE=/vmlinuz-<kernel version> root=/dev/mapper/openeuler-root ro resume=/dev/mapper/openeuler-swap rd.lvm.lv=openeuler/root rd.lvm.lv=openeuler/swap crashkernel=512M quiet audit=1 audit_backlog_limit=8192
```

**修复方法：**

* 修改grub.cfg文件，直接在对应内核启动参数后面添加，需要注意的是，grub.cfg文件所在目录根据系统安装配置会有不同，大部分情况存在于/boot/grub2/或/boot/efi/EFI/openEuler/目录下：

  ```bash
  # vim /boot/grub2/grub.cfg
  linuxefi	/vmlinuz-<kernel version> root=/dev/mapper/openeuler-root ro resume=/dev/mapper/openeuler-swap rd.lvm.lv=openeuler/root rd.lvm.lv=openeuler/swap crashkernel=512M quiet audit=1 audit_backlog_limit=<size>
  ```

* 或者修改配置文件/etc/default/grub，在GRUB_CMDLINE_LINUX字段添加“audit_backlog_limit=\<size>”，然后重新生成grub.cfg文件：

  ```bash
  # /etc/default/grub
  GRUB_CMDLINE_LINUX="/dev/mapper/openeuler-swap rd.lvm=openeuler/root rd.lvm.lv=openeuler/swap crashkernel quiet audit=1 audit_backlog_limit=<size>"
  
  # grub2-mkconfig -o /boot/grub2/grub.cfg
  ```

* 修改后重启系统生效：

  ```bash
  # reboot
  ```
### 4.1.10 避免使用auditctl设置auditd规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

auditd服务规则可以在/etc/audit/rules.d/目录下的规则文件中配置后，重启服务器生效，也可以通过auditctl命令设置，并立即生效。/etc/audit/rules.d/目录权限为750，而auditctl权限为755，所以禁止通过auditctl命令修改auditd服务规则，可以缩小攻击面，防止低权限攻击者通过命令行修改规则并立即实施攻击行为。

openEuler，默认不禁止通过auditctl命令修改auditd服务规则，建议用户根据业务场景，禁用auditctl方式设置。

**规则影响：**

无

**检查方法：**

通过grep命令，检查/etc/audit/rules.d/目录下是否存在特定的rules文件，包含有“-e 2”字段：

```bash
# grep "-e 2" /etc/audit/rules.d/*.rules
/etc/audit/rules.d/immutable.rules:-e 2
```

**修复方法：**

在/etc/audit/rules.d/目录下新建以.rules为后缀的规则文件（可随意命名），添加“-e 2”字段：

```bash
# vim /etc/audit/rules.d/immutable.rules
-e 2
```

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.11 确保日志大小限制配置正确

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

audit日志文件需要配置大小限制，达到限制后通过rotate机制，新建日志文件重新记录，可以防止单个文件过大问题，便于管理和追溯。配置上限过大，容易导致单个日志文件过大，不利于管理；配置上限过小，则容易导致过多的日志文件或者日志文件因rotate机制被频繁覆盖，不利于事后追溯。

openEuler默认配置8MB，用户可根据实际场景修改配置。

**规则影响：**

无

**检查方法：**

使用如下命令查看当前配置：

```bash
# grep "^max_log_file" /etc/audit/auditd.conf
max_log_file = 8
max_log_file_action = ROTATE
```
**修复方法：**

修改/etc/audit/auditd.conf文件中max_log_file字段的值（单位是MB）：

```bash
# vim /etc/audit/auditd.conf
max_log_file = <numeric value in megabytes>
```

重启auditd服务，使配置生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.12 应当正确配置硬盘空间阈值

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

在auditd记录日志过程中，如果硬盘空间被写满，可能导致业务无法正常执行，所以需要提前设置相关配置项，确保硬盘在即将写满或已经写满的情况下不至于引起更加严重的系统问题。

配置文件/etc/audit/auditd.conf的如下相关项openEuler已配置默认值，用户可根据业务场景修改：

| 配置项                  | 默认值  | 说明                                                         |
| ----------------------- | ------- | ------------------------------------------------------------ |
| space_left              | 75      | 配置硬盘空间下限告警动作阈值，如低于75MB，则触发space_left_action定义的告警动作 |
| space_left_action       | SYSLOG  | 硬盘空间低于space_left时，触发告警事件，可选：IGNORE、SYSLOG、EMAIL、SUSPEND、SINGLE、HALT。  openEuler默认设置为SYSLOG，表示不会阻止继续记录日志，但会通过syslog记录一次告警。 |
| admin_space_left        | 50      | 配置硬盘空间下限管理动作阈值，如低于50MB，则触发admin_space_left_action定义的操作动作，admin_space_left设置值不能大于space_left的值。 |
| admin_space_left_action | SUSPEND | 硬盘空间低于admin_space_left时，触发管理事件，可选：IGNORE、SYSLOG、EMAIL、SUSPEND、SINGLE、HALT。  openEuler默认设置为SUSPEND，表示auditd服务停止向硬盘输出日志记录。 |
| disk_full_action        | SUSPEND | 表示如果系统检测到硬盘已经写满，则触发处理动作，可选：IGNORE、SYSLOG、SUSPEND、SINGLE、HALT。  openEuler默认设置为SUSPEND，表示auditd服务停止向硬盘输出日志记录。 |
| disk_error_action       | SUSPEND | 表示如果在记录audit日志时，检测到硬盘错误，则触发处理动作，可选：IGNORE、SYSLOG、SUSPEND、SINGLE、HALT。  openEuler默认设置为SUSPEND，表示auditd服务停止向硬盘输出日志记录。 |

如果告警阈值和管理阈值配置过大，则可能硬盘还有较大空间时audit日志就无法正常输出，如果配置过小，则会因为日志输出而将硬盘空间耗尽，影响正常业务，所以建议一方用户根据实际场景配置合理值，另一方面建议将日志输出到单独分区，避免日志过大影响业务。

**规则影响：**

无

**检查方法：**

通过如下方法检查/etc/audit/auditd.conf文件是否配置正确：

```bash
# cat /etc/audit/auditd.conf | grep -iE "space_left|space_left_action|admin_space_left|admin_space_left_action|disk_full_action|disk_error_action"
space_left = 75
space_left_action = SYSLOG
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
```

**修复方法：**

修改/etc/audit/auditd.conf文件，配置对应字段内容：

```bash
# vim /etc/audit/auditd.conf
space_left = <numeric value in megabytes>
space_left_action = <action>
admin_space_left = <numeric value in megabytes>
admin_space_left_action = <action>
disk_full_action = <action>
disk_error_action = <action>
```

重启auditd服务，使配置生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.13 应当配置sudoers审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

sudo命令允许普通用户提权执行root管理员权限相关的操作，属于高危操作，攻击者一般无法直接获取root权限，但通过sudo命令提权，相对比较容易。建议配置对/etc/sudoers文件以及/etc/sudoers.d/目录审计，记录读、写操作的审计日志，从而追溯是否有配置修改或读取操作（提权操作需要读取配置）。如果不配置sudoers审计，发生非法提权操作时不利于追溯。

openEuler默认不配置sudoers审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置sudoers审计，由于在文件操作时需要记录审计日志，对性能有轻微影响。

**检查方法：**

通过如下方法，检查是否存在针对/etc/sudoers文件以及/etc/sudoers.d/目录的审计规则：

```bash
# auditctl -l | grep "sudoers"
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d -p wa -k sudoers
```

**修复方法：**

在/etc/audit/rules.d/目录下新建规则文件，例如sudoers.rules，在文件中添加审计规则：

```bash
# vim /etc/audit/rules.d/sudoers.rules
-w /etc/sudoers -p wa -k <rules name>
-w /etc/sudoers.d -p wa -k <rules name>
```

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.14 应当配置会话审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

建议对/var/run/utmp、/var/log/wtmp、/var/log/btmp三个文件进行审计监控，utmp文件记录了当前所有的登录事件信息；wtmp文件记录了所有的登录、登出、关机、重启事件信息，btmp记录了登录失败事件信息。如果不配置会话审计，管理员无法从audit日志中追溯登录、登出等事件，或可追溯信息不够。

openEuler默认不配置会话审计规则，建议用户根据实际业务场景进行配置。

**规则影响：**

配置会话审计，由于在文件操作时需要记录审计日志，对性能有轻微影响，但由于登录、登出动作本身不应快速、频繁发生，用户无感知。

**检查方法：**

通过如下方法，检查是否存在针对/var/run/utmp、/var/log/wtmp、/var/log/btmp文件的审计规则：

```bash
# auditctl -l | grep -iE "utmp|wtmp|btmp"
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session
```

**修复方法：**

在/etc/audit/rules.d/目录下新建规则文件，例如session.rules，在文件中添加审计规则：

```bash
# vim /etc/audit/rules.d/session.rules
-w /var/run/utmp -p wa -k <rules name>
-w /var/log/wtmp -p wa -k <rules name>
-w /var/log/btmp -p wa -k <rules name>
```

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.15 应当配置时间修改审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

系统时间是否准确，影响着业务的正常运行。除了通过时间同步服务器确保时间同步之外，还需要关注管理员通过手工命令方式修改系统时间，后者往往伴随着攻击风险，如攻击者通过修改系统时间使某些保护策略失效（例如口令过期），达成攻击目的。

建议通过审计系统调用（adjtimex、settimeofday、clock_settime），对系统时间修改进行日志记录，同时对/etc/localtime文件进行审计，记录时区变更日志。如果不配置时间修改审计，管理员无法从audit日志中追溯时间变更事件。

openEuler默认不配置时间修改审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置时间变更审计，由于在文件操作或系统调用时需要记录审计日志，对性能有轻微影响，但由于时间变更动作本身不应快速、频繁发生，用户无感知。

**检查方法：**

如果是32位系统，通过如下命令检查配置：

```bash
# auditctl -l | grep -iE "adjtimex|settimeofday|clock_settime|localtime"
-a always,exit -F arch=b32 -S stime,settimeofday,adjtimex,clock_settime -F key=time
-w /etc/localtime -p wa -k time
```
如果是64位系统，还需有如下配置：

```bash
-a always,exit -F arch=b64 -S settimeofday,adjtimex,clock_settime -F key=time
```

**修复方法：**

如果是32位系统，在/etc/audit/rules.d/目录下新建规则文件，例如time.rules，在文件中添加审计规则：

```bash
# vim /etc/audit/rules.d/time.rules
-a always,exit -F arch=b32 -S stime -S settimeofday -S adjtimex -S clock_settime -k <rules name>
-w /etc/localtime -p wa -k <rules name>
```
如果是64位系统，需要再添加arch=b64相关配置：
```bash
-a always,exit -F arch=b64 -S settimeofday -S adjtimex -S clock_settime -k <rules name>
```
考虑兼容性，64位系统中arch=b32相关配置必须保留。

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.16 应当配置SELinux审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

SELinux是Linux平台提供的强制访问控制功能组件，用于对进程、文件等进行细粒度的权限控制。建议对SELinux配置文件、策略文件等配置审计，记录修改日志。如果不配置SELinux审计，如果发生非法策略修改，不利于追溯。

openEuler默认不配置SELinux审计规则，建议用户根据实际业务场景进行配置。

**规则影响：**

配置SELinux审计，由于在策略文件操作时需要记录审计日志，对性能有轻微影响。

**检查方法：**

通过如下命令检查selinux相关审计配置：

```bash
# auditctl -l | grep -iE "selinux"
-w /etc/selinux -p wa -k selinux
-w /usr/share/selinux -p wa -k selinux
```

**修复方法：**

在/etc/audit/rules.d/目录下新建规则文件，例如selinux.rules，在文件中添加审计规则：

```bash
# vim /etc/audit/rules.d/selinux.rules
-w /etc/selinux/ -p wa -k <rules name>
-w /usr/share/selinux/ -p wa -k <rules name>
```

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.17 应当配置网络环境审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

攻击者可能通过修改系统域名、主机名等实施攻击行为，比如主机欺骗等，建议用户通过设置对系统调用setdomainname、sethostname的审计，以及文件/etc/hosts的审计，监控系统域名、主机名的修改；通过设置对/etc/issue、/etc/issue.net文件的审计，监控登录提示信息的修改。

如果不配置相关审计，如果发生非法修改，不利于追溯。

openEuler默认不配置网络环境审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置审计，由于在文件操作时需要记录审计日志，对性能有轻微影响，但由于域名、主机名以及登录提示信息不应被频繁修改，实际对用户无感知。

**检查方法：**

如果是32位系统，通过如下命令检查配置：

```bash
# auditctl -l | grep -iE "setdomainname|sethostname|hosts|issue"
-a always,exit -F arch=b32 -S sethostname,setdomainname -F key=hostnet
-w /etc/hosts -p wa -k hostnet
-w /etc/issue -p wa -k hostnet
-w /etc/issue.net -p wa -k hostnet
```

如果是64位系统，还需有如下配置：
```bash
-a always,exit -F arch=b64 -S sethostname,setdomainname -F key=hostnet
```

**修复方法：**

如果是32位系统，在/etc/audit/rules.d/目录下新建规则文件，例如hostnet.rules，在文件中添加审计规则：

```bash
# vim /etc/audit/rules.d/hostnet.rules
-a always,exit -F arch=b32 -S setdomainname -S sethostname -k <rules name>
-w /etc/hosts -p wa -k <rules name>
-w /etc/issue -p wa -k <rules name>
-w /etc/issue.net -p wa -k <rules name>
```
如果是64位系统，需要再添加arch=b64相关配置：
```bash
-a always,exit -F arch=b64 -S setdomainname -S sethostname -k <rules name>
```
考虑兼容性，64位系统中arch=b32相关配置必须保留。

重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.18 应当配置文件访问控制权限审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

文件访问权限控制是Linux中基础的权限管理，不同用户被授权可以访问不同的文件，防止用户之间敏感信息泄露或文件数据被篡改，也可以防止普通用户越权访问系统高权限文件或配置。

建议对操作系统中修改文件权限、文件属主的系统调用进行审计监控。如果不配置相关审计，如果发生非法修改，不利于追溯。

openEuler默认不配置文件访问控制权限审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置审计，由于在文件权限、属主修改时需要记录审计日志，对性能有轻微影响，但由于此类操作不应被频繁执行，实际对用户无感知。

**检查方法：**

如果是32位系统，通过如下命令检查配置：

```bash
# auditctl -l | grep -iE "chmod|chown|setxattr|exattr"
-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=-1 -F key=fileperm
-a always,exit -F arch=b32 -S chown,fchown,lchown,fchownat -F auid>=1000 -F auid!=-1 -F key=fileperm
-a always,exit -F arch=b32 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=-1 -F key=fileperm
```
如果是64位系统，还需有如下配置：

```bash
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=-1 -F key=fileperm
-a always,exit -F arch=b64 -S chown,fchown,lchown,fchownat -F auid>=1000 -F auid!=-1 -F key=fileperm
-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=-1 -F key=fileperm
```

**修复方法：**

如果是32位系统，在/etc/audit/rules.d/目录下新建规则文件，例如fileperm.rules，在文件中添加审计规则，此处\<min uid\>是/etc/login.defs文件中UID_MIN（UID_MIN为通过useradd方式添加用户，用户uid的最小值），openEuler上默认是1000：

```bash
# vim /etc/audit/rules.d/fileperm.rules
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=<min uid> -F auid!=unset -k <rules name>
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=<min uid> -F auid!=unset -k <rules name>
-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=<min uid> -F auid!=unset -k <rules name>
```
如果是64位系统，需要再添加arch=b64相关配置：
```bash
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=<min uid> -F auid!=unset -k <rules name>
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=<min uid> -F auid!=unset -k <rules name>
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=<min uid> -F auid!=unset -k <rules name>
```
考虑兼容性，64位系统中arch=b32相关配置必须保留。
重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.19 应当配置文件访问失败审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

通过对open、truncate、ftruncate、create、openat等系统调用进行审计监控，如果这些系统调用返回“-EACCES”或“-EPERM”错误，则表示文件无权访问，需要记录审计日志。由于权限问题导致文件访问失败的场景，在攻击行为中比较常见，建议配置审计规则，以便事后追溯。

openEuler默认不配置文件访问失败审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置审计，由于在文件访问失败时需要进行审计日志记录，对性能有轻微影响，但在实际场景中，文件访问失败的场景较少，影响有限。

**检查方法：**

如果是32位系统，通过如下命令检查配置：

```bash
# auditctl -l | grep -iE "EACCES|EPERM"
-a always,exit -F arch=b32 -S open,truncate,ftruncate,creat,openat -F exit=-EACCES -F auid>=1000 -F auid!=-1 -F key=fileaccess
-a always,exit -F arch=b32 -S open,truncate,ftruncate,creat,openat -F exit=-EPERM -F auid>=1000 -F auid!=-1 -F key=fileaccess
```
如果是64位系统，还需有如下配置：

```bash
-a always,exit -F arch=b64 -S open,truncate,ftruncate,creat,openat -F exit=-EACCES -F auid>=1000 -F auid!=-1 -F key=fileaccess
-a always,exit -F arch=b64 -S open,truncate,ftruncate,creat,openat -F exit=-EPERM -F auid>=1000 -F auid!=-1 -F key=fileaccess
```

**修复方法：**

如果是32位系统，在/etc/audit/rules.d/目录下新建规则文件，例如fileaccess.rules，在文件中添加审计规则，此处\<min uid>是/etc/login.defs文件中UID_MIN的值，openEuler上默认是1000：

```bash
# vim /etc/audit/rules.d/fileaccess.rules
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=<min uid> -F auid!=unset -k <rules name>
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=<min uid> -F auid!=unset -k <rules name>
```
如果是64位系统，需要再添加arch=b64相关配置：
```bash
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=<min uid> -F auid!=unset -k <rules name>
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=<min uid> -F auid!=unset -k <rules name>
```
考虑兼容性，64位系统中arch=b32相关配置必须保留。
重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.20 应当配置文件删除审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

操作系统中文件删除操作一般都属于高危操作，管理员误操作或者攻击者攻击行为，都可能导致严重的系统故障，建议通过对rename、unlink、unlinkat、renameat等系统调用进行审计监控，记录删除操作日志。删除系统或业务文件，在攻击行为中比较常见，建议配置审计规则，以便事后追溯。

openEuler默认不配置文件删除审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置审计，由于在文件删除时需要进行审计日志记录，对性能有轻微影响，如果实际业务场景存在大量文件删除操作，则累积影响可能较大。

**检查方法：**

如果是32位系统，通过如下命令检查配置：

```bash
# auditctl -l | grep -iE "unlink|unlinkat|rename|renameat"
-a always,exit -F arch=b32 -S rename,unlink,unlinkat,renameat -F auid>=1000 -F auid!=-1 -F key=filedelete
```
如果是64位系统，还需有如下配置：

```bash
-a always,exit -F arch=b64 -S rename,unlink,unlinkat,renameat -F auid>=1000 -F auid!=-1 -F key=filedelete
```
**修复方法：**

如果是32位系统，在/etc/audit/rules.d/目录下新建规则文件，例如filedelete.rules，在文件中添加审计规则，此处\<min uid>是/etc/login.defs文件中UID_MIN的值，openEuler上默认是1000：

```bash
# vim /etc/audit/rules.d/filedelete.rules
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=<min uid> -F auid!=unset -k <rules name>
```
如果是64位系统，需要再添加arch=b64相关配置：

```bash
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=<min uid> -F auid!=unset -k <rules name>
```
考虑兼容性，64位系统中arch=b32相关配置必须保留。
重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
### 4.1.21 应当配置文件系统挂载审计规则

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

通常情况下，业务部署完成后，文件系统挂载已经固定，不会变更。如果发生变更，可能存在攻击行为，建议对这些文件系统挂载进行审计监控，如果有变更，事后也可进行追溯。

openEuler默认不配置文件系统挂载审计规则，建议用户根据实际业务场景配置相应规则。

**规则影响：**

配置审计，由于在文件系统挂载时需要进行审计日志记录，对性能有轻微影响，但文件系统挂载相关操作应不频繁，实际对用户无感知。

**检查方法：**

如果是32位系统，通过如下命令检查配置：

```bash
# auditctl -l | grep -iE "mount"
-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=-1 -F key=mount
```
如果是64位系统，还需有如下配置：

```bash
-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=-1 -F key=mount
```

**修复方法：**

如果是32位系统，在/etc/audit/rules.d/目录下新建规则文件，例如mount.rules，在文件中添加审计规则，此处\<min uid>是/etc/login.defs文件中UID_MIN的值，openEuler上默认是1000：

```bash
# vim /etc/audit/rules.d/mount.rules
-a always,exit -F arch=b32 -S mount -F auid>=<min uid> -F auid!=unset -k <rules name>
```
如果是64位系统，需要再添加arch=b64相关配置：

```bash
-a always,exit -F arch=b64 -S mount -F auid>=<min uid> -F auid!=unset -k <rules name>
```
考虑兼容性，64位系统中arch=b32相关配置必须保留。
重启auditd服务，使规则生效：

```bash
# service auditd restart
Stopping logging: [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
## 4.2 Rsyslog
### 4.2.1 确保rsyslog服务已启用

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

当前系统日志默认存储在内存，若不开启rsyslog服务，系统日志无法转储到持久性存储设备，系统重启后，会导致日志丢失。

rsyslog服务用于转储、分发系统日志，具有以下特点：

- 多线程工作
- 支持UDP、TCP、SSL、TLS、RELP
- 支持将日志存储到MySQL、PGSQL、Oracle等多种关系数据库中
- 支持日志信息过滤
- 自定义输出格式

**规则影响：**

无

**检查方法：**

- 执行如下命令，查看rsyslog.service服务默认状态是否为enable

  ```bash
  # systemctl is-enabled rsyslog.service
  enabled
  ```

- 执行如下命令，查看rsyslog.service服务是否已经启动成功：

  ```bash
  # systemctl status rsyslog.service | grep Active
  Active: active (running) since Tue 2020-12-01 16:33:25 CST; 2h 46min ago
  ```

**修复方法：**

- 执行如下命令，使能rsyslog.service

  ```bash
  # chkconfig rsyslog on
  ```
  或
  ```bash
  # systemctl enable rsyslog.service
  ```
- 执行如下命令，启动rsyslog.service

  ```bash
  # systemctl start rsyslog.service
  ```
### 4.2.2 确保系统认证相关事件日志已记录

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

必须记录系统认证相关的事件，以便帮助分析用户登录、root权限使用以及监视系统的可疑动作等情况。

不记录系统认证相关事件日志，会导致无法从日志上分析可疑的攻击动作，例如攻击者尝试猜测管理员口令，而进行的登录动作。

**规则影响：**

无

**检查方法：**

检查/etc/rsyslog.conf文件中是否已经配置auth相关字段：

```bash
# grep auth /etc/rsyslog.conf | grep -v "^#"
*.info;mail.none;authpriv.none;cron.none           /var/log/messages
authpriv.*                                         /var/log/secure
```

**修复方法：**

在/etc/rsyslog.conf文件添加如下设置：

```bash
# vim /etc/rsyslog.conf
*.info;mail.none;authpriv.none;cron.none           /var/log/messages
authpriv.*                                         /var/log/secure
```

执行如下命令，重启服务，使配置生效

```bash
# systemctl restart rsyslog.service
```
### 4.2.3 确保cron服务日志已记录

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

linux系统计划任务一般由cron来承担，由于cron可能会被黑客利用来加载恶意代码，因此需要全部记录cron的日志信息，以便跟踪系统异常状况。

不记录cron日志，当出现攻击者恶意操作时，将无法从日志信息中查看异常，进而无法跟踪系统异常状况。

**规则影响：**

无

**检查方法：**

检查/etc/rsyslog.conf文件中是否已经配置相关字段：

```bash
# grep /var/log/cron /etc/rsyslog.conf
cron.*                                                  /var/log/cron
```

**修复方法：**

修改/etc/rsyslog.conf文件，添加cron相关配置字段：

```bash
# vim /etc/rsyslog.conf
cron.*                                                  /var/log/cron
```

执行如下命令，重启服务，使配置生效

```bash
# systemctl restart rsyslog.service
```
### 4.2.4 应当正确配置rsyslog默认文件权限

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

日志文件记录了系统的行为，日志工具rsyslog能将日志记录到设定的文件中。当设定的日志文件在系统中不存在时，rsyslog能创建新日志文件。新创建的日志文件权限可在rsyslog配置文件中进行配置，通过设置默认文件权限以确保新创建的日志文件具有合理安全的权限。

若日志文件权限过大，普通用户也能读取日志，则增加了日志信息泄漏和被篡改的风险。合理的日志文件权限确保敏感的日志数据能得到保护。建议将日志权限设置为0600。

**规则影响：**

无

**检查方法：**

检查/etc/rsyslog.conf或/etc/rsyslog.d/*.conf配置文件是否配置了合理的默认文件权限，如果指令存在返回值且FileCreateMode的值不为0600，则说明系统日志信息存在泄露和被篡改的风险，需对日志文件权限进行修复。

```bash
# grep ^\$FileCreateMode /etc/rsyslog.conf /etc/rsyslog.d/*.conf
/etc/rsyslog.d/sysalarm.conf:$FileCreateMode 0600
```

**修复方法：**

修改/etc/rsyslog.conf或/etc/rsyslog.d/*.conf，为$FileCreateMode设置合理的权限：

```bash
# vim /etc/rsyslog.d/test.conf
$FileCreateMode 0600
```

rsyslog.conf中默认会包含/etc/rsyslog.d/*.conf中的配置，因此配置任何一处即可。

执行如下命令，重启服务，使配置生效

```bash
# systemctl restart rsyslog.service
```
### 4.2.5 应当正确配置各服务日志记录

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

配置日志记录，这样系统的重要行为及安全相关的信息将使用rsyslog进行记录。配置文件/etc/rsyslog.conf及/etc/rsyslog.d/*.conf中可以指定记录日志的规则及哪些文件将用于记录特定类型的日志。

若不配置日志记录，系统的行为无法记录，在出现问题时无法进行问题定位及审计。

**规则影响：**

配置日志记录后，如果不及时清理日志，日志可能占满当前分区，导致其他进程或系统故障风险。

**检查方法：**

检查/etc/rsyslog.conf及/etc/rsyslog.d/*.conf中是否配置了合理的日志记录规则，例如：

```bash
# grep \/var\/log /etc/rsyslog.conf /etc/rsyslog.d/*.conf
/etc/rsyslog.conf:*.info;mail.none;authpriv.none;cron.none        /var/log/messages
/etc/rsyslog.conf:authpriv.*                                 /var/log/secure
/etc/rsyslog.conf:mail.*                                    /var/log/maillog
/etc/rsyslog.conf:cron.*                                    /var/log/cron
/etc/rsyslog.conf:uucp,news.crit                             /var/log/spooler
/etc/rsyslog.conf:local7.*                                  /var/log/boot.log
```

**修复方法：**

在/etc/rsyslog.conf及/etc/rsyslog.d/*.conf中配置合理的日志记录规则，以/etc/rsyslog.conf为例：

```bash
# vim /etc/rsyslog.conf
/etc/rsyslog.conf:*.info;mail.none;authpriv.none;cron.none        /var/log/messages
/etc/rsyslog.conf:authpriv.*                                 /var/log/secure
/etc/rsyslog.conf:mail.*                                    /var/log/maillog
/etc/rsyslog.conf:cron.*                                    /var/log/cron
/etc/rsyslog.conf:uucp,news.crit                             /var/log/spooler
/etc/rsyslog.conf:local7.*                                  /var/log/boot.log
```

系统管理员在配置日志规则时，按需进行合理配置。以mail日志为例，“*”表示所有级别的日志；“/var/log/maillog”意思是mail相关的日志记录到该文件中。具体的日志配置规则可参考rsyslog标准。

执行如下命令，重启服务，使配置生效

```bash
# systemctl restart rsyslog.service
```
### 4.2.6 确保rsyslog转储journald日志已配置

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

系统采用journald进行日志收集，日志可能存在易失性存储设备上，也有可能存储在持久性存储设备上，存在日志丢失或者日志占满磁盘等问题，及时对日志进行转储，保障日志与系统更加安全。

**规则影响：**

日志如果存在易失性存储设备，不及时对日志进行转储，可能导致日志丢失。如果存在持久性存储设备上，日志量可能非常大，不及时对日志进行转储，有可能导致日志占满当前分区，导致其他进程或系统故障风险。

**检查方法：**

检查/etc/rsyslog.conf文件中是否已经配置相关字段，如果返回结果不为空，表示已配置：

```bash
# grep imjournal /etc/rsyslog.conf
module(load="imjournal"   # provides access to the systemd journal
StateFile="/run/log/imjournal.state") # File to store the position in the journal
```

**修复方法：**

打开/etc/rsyslog.conf文件，新增如下设置：

```bash
# vim /etc/rsyslog.conf
module(load="imjournal"   # provides access to the systemd journal
StateFile="/run/log/imjournal.state") # File to store the position in the journal
```

执行如下命令，重启服务，使配置生效

```bash
# systemctl restart rsyslog.service
```
### 4.2.7 确保rsyslog日志rotate已配置

**级别：** 要求

**适用版本：** 全部

**规则说明：** 

rsyslog负责从系统中收集日志记录到文件中，logrotate负责定期或定量对日志文件进行拷贝、压缩，以确保不会因为日志文件过大而导致占用过多的硬盘资源，甚至日志文件不可维护。

如果不配置rotate策略，日志文件会一直增长，最终可能导致日志所在硬盘分区空间耗尽，轻则影响日志记录，重则可能导致系统和业务无法继续正常执行。

openEuler默认已经在/etc/logrotate.d/rsyslog文件中配置rsyslog的rotate策略如下：

* rotate日志文件

  /var/log/cron

  /var/log/maillog

  /var/log/messages

  /var/log/secure

  /var/log/spooler

* 日志文件最大保留期限365天；

* 日志文件最多保留30个；

* 日志文件采用压缩方式保留；

* 日志文件达到4MB，进行rotate操作。

**规则影响：**

无

**检查方法：**

检查/etc/logrotate.d/rsyslog文件中是否已经配置相关字段，此处“/var/log/*”是/etc/rsyslog.conf文件中配置的rsyslog日志输出路径，两者需要匹配一致：

```bash
# cat /etc/logrotate.d/rsyslog | grep -iE "\/var\/log|maxage|\<rotate\>|compress|size"
/var/log/cron
/var/log/maillog
/var/log/messages
/var/log/secure
/var/log/spooler
    maxage 365
    rotate 30
    compress
    size +4096k
```

**修复方法：**

在/etc/logrotate.d目录下创建配置文件，比如/etc/logrotate.d/rsyslog文件，检查并新增如下设置，其中\<log file paths>是/etc/rsyslog.conf文件中配置的rsyslog日志输出路径，两者需要匹配一致：

```bash
# vim /etc/logrotate.d/rsyslog
<log file paths>
{
    maxage <days>
    rotate <files counts>
    notifempty
    compress
    copytruncate
    missingok
    size +<numeric value in kilobyte>k
    sharedscripts
    postrotate
        /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}
```
### 4.2.8 应当配置远程日志服务器

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

rsyslog日志服务可以将本地日志发送到远端日志服务器统一保存，有利于组网环境下日志集中管理，防止本地日志占用过多硬盘空间的同时，也可以防止日志在本地被篡改。

如果不配置远程日志存储，则rsyslog日志会保存在本地文件中，管理员正确配置日志存储路径以及rotate参数的情况下，对系统及业务无影响。如果配置了远程日志存储，就必须保证日志传输过程安全，如传输日志前进行加密、通过开启安全加密通道（TCP+TLS1.2及更高版本）等方法进行日志传输。

openEuler默认不配置远程日志存储，建议用户根据实际业务场景进行配置。

**规则影响：**

配置远程日志存储，则需要确保日志服务器有足够的硬盘空间用于存储组网环境下所有服务器上报的日志。

**检查方法：**

检查/etc/rsyslog.d/目录下配置文件中是否已经配置相关字段：

```bash
# grep -irE "^*.*@*:[0-9]+$" /etc/rsyslog.d/*.conf
/etc/rsyslog.d/server.conf:*.* @@9.82.213.138:11514
```

**修复方法：**

在/etc/rsyslog.d/目录下新建以conf为后缀的配置文件，例如server.conf，然后加入配置如下，其中“*.*” 指将所有的日志都打印到服务器（含义是：日志类型.日志级别，mail.info就表示只将mail的info日志打印到服务器），“@”表示使用UDP协议，“@@”表示使用TCP协议：

```bash
# vim /etc/rsyslog.d/server.conf
*.* @@<remote IP>:<remote port>
# 如果是IPv6，则添加如下配置:
*.* @@[<remove IPv6>%<interface name>]:<remote port>
```

执行如下命令，重启服务，使配置生效

```bash
# systemctl restart rsyslog.service
```
### 4.2.9 应当仅在指定的日志主机上接受远程rsyslog消息

**级别：** 建议

**适用版本：** 全部

**规则说明：** 

默认情况下，rsyslog不会监听来自远程系统的日志消息。rsyslog需加载imtcp.so模块才能通过TCP监听，同理需要加载imudp.so模块才能通过UDP监听，两者都需要指定监听的TCP/UDP端口。确保只在指定的日志主机上接收远程rsyslog消息，以便管理员集中管理，但需要确保日志服务器有足够的硬盘空间用于存储组网环境下所有服务器上报的日志。

**规则影响：**

无

**检查方法：**

运行如下命令检查/etc/rsyslog.conf及/etc/rsyslog.d/*.conf配置文件：

* 检查TCP配置：

  ```bash
  # grep ^\$ModLoad /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep imtcp
  /etc/rsyslog.conf:$ModLoad imtcp
  # grep ^\$InputTCPServerRun /etc/rsyslog.conf /etc/rsyslog.d/*.conf
  /etc/rsyslog.conf:$InputTCPServerRun 11514
  ```

* 检查UDP配置：

  ```bash
  # grep ^\$ModLoad /etc/rsyslog.conf /etc/rsyslog.d/*.conf | grep imudp
  /etc/rsyslog.conf:$ModLoad imudp
  # grep ^\$InputUDPServerRun /etc/rsyslog.conf /etc/rsyslog.d/*.conf
  /etc/rsyslog.conf:$InputUDPServerRun 11514
  ```

**修复方法：**

修改/etc/rsyslog.conf或/etc/rsyslog.d/*.conf，配置接受远程rsyslog消息，并根据客户端IP单独存放在不同目录，可以自定义指定目录：

* 修复TCP配置：

  ```bash
  # vim /etc/rsyslog.conf
  $ModLoad imtcp
  $InputTCPServerRun 11514
  $template Remote, "/var/log/syslog/%fromhost-ip%/%$YEAR%-%$MONTH%-%$DAY%.log"
  ```

* 修复UDP配置：

  ```bash
  # vim /etc/rsyslog.conf
  $ModLoad imudp
  $InputUDPServerRun 11514
  $template Remote, "/var/log/syslog/%fromhost-ip%/%$YEAR%-%$MONTH%-%$DAY%.log"
  ```

* 执行如下命令，重启服务，使配置生效

  ```bash
  # systemctl restart rsyslog.service
  ```