sudo apt-get install --no-install-recommends flex bison build-essential csh
sudo mkdir -p /usr/class
sudo chown $USER /usr/class
cd /usr/class
wget http://spark-university.s3.amazonaws.com/stanford-compilers/vm/student-dist.tar.gz
tar -xf student-dist.tar.gz
ln -s /usr/class/cs143/cool ~/cool
new_path='PATH=/usr/class/cs143/cool/bin:$PATH'

SH_CONF=$HOME/.bashrc

if test -f $HOME/.zshrc
then
	SH_CONF=$HOME/.zshrc
fi

if ! grep "$new_path" $SH_CONF
then
	echo "$new_path" >> $SH_CONF
fi
