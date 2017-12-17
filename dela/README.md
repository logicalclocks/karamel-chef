#run vms
1. run prepare step
```./dela/prepare.sh```
2. generate dela env file based on default
```dela/defaults/dela_env.sh```
3. generate the ports for this vm
```./dela/dela_gen_ports ./dela/defauls/dela_env.sh```
4. create the vm
```./dela/dela_run.sh```