#!/bin/bash

pkill VBoxHeadless

sleep 5
pkill VBoxSVC

vagrant destroy -f
