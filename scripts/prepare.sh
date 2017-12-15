#!/bin/bash
set -e

if [ ! -f "scripts/prepare.sh" ]; then
    echo "Running the script from the karamel-chef dir"
fi

mkdir VBox
cat "#!/bin/bash" > vbox.sh
cat "VBoxManage setproperty machinefolder `pwd`/VBox" >> vbox.sh
chmod +x vbox.sh
