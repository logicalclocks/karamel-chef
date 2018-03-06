#!/bin/bash
set -e

if [ ! -d "dela" ]; then
    echo "Run the script from the karamel-chef dir"
fi

mkdir VBox
touch vbox.sh
echo "#!/bin/bash" > vbox.sh
echo "VBoxManage setproperty machinefolder `pwd`/VBox" >> vbox.sh
chmod +x vbox.sh
