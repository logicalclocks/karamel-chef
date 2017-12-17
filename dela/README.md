#run hopssite vm
1. run prepare step
```./dela/prepare.sh```
2. generate dela env file based on default
```dela/defaults/hs_env.sh```
3. generate the ports for this vm
```./dela/hs_1.sh ./dela/defauls/hs_env.sh```
4. create the vm
```./dela/hs_2.sh```
5. register
```./dela/hs_3.sh```

#run dela vm
1. run prepare step
```./dela/prepare.sh```
2. generate dela env file based on default
```dela/defaults/dela_env.sh```
3. generate the ports for this vm
```./dela/dela_1.sh ./dela/defauls/dela_env.sh```
4. create the vm
```./dela/dela_2.sh```
5. register
```./dela/dela_3.sh```