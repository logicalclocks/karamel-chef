#run bbc5 hopssite mirror vm
1. run prepare step
```./dela/prepare.sh```
2. create env file based on default
```dela/defaults/hs_env.sh```
3. generate vagrantfile and cluster-def
```./dela/bbc5_hs_1.sh ./dela/defauls/hs_env.sh```
4. create the vm
```./dela/hs_2.sh```
5. register & install hopssite
```./dela/hs_3.sh```

#run hopssite vm
1. run prepare step
```./dela/prepare.sh```
2. create env file based on default
```dela/defaults/hs_env.sh```
3. generate vagrantfile and cluster-def
```./dela/hs_1.sh ./dela/defauls/hs_env.sh```
4. create the vm
```./dela/hs_2.sh```
5. register & install hopssite
```./dela/hs_3.sh```

#run dela vm
1. run prepare step
```./dela/prepare.sh```
2. create env file based on default
```dela/defaults/dela_env.sh```
3. generate vagrantfile and cluster-def
```./dela/dela_1.sh ./dela/defauls/dela_env.sh```
4. create the vm
```./dela/dela_2.sh```

#run demodela
Running the cluster-defns/1.demodela.yml requires you to change some of the parameters. 
If you want to run demodela without having to change anything, you can:
1. run
```./dela/demodela.sh```
2. check the cluster file to see the randomly filled variables
```cluster-defns/1.demodela.yml```
