#!/bin/bash

echo "Check if Vagrantfile exists"

echo -e "\nView Vagrantfile content"
ls -la Vagrantfile
echo " _______________________________________________"

echo -e "\nCheck VM status and configuration"
vagrant status
echo " _______________________________________________"

echo -e "\nVerify OS versions"
echo "Server OS:"
vagrant ssh mochegriS -c "cat /etc/os-release"
echo -e "\nWorker OS:"
vagrant ssh mochegriSW -c "cat /etc/os-release" 
echo " _______________________________________________"

echo -e "\nCheck network configuration"
echo "Server eth1:"
vagrant ssh mochegriS -c "ifconfig eth1"
echo -e "\nWorker eth1:"
vagrant ssh mochegriSW -c "ifconfig eth1"
echo " _______________________________________________"

echo -e "\nVerify hostnames" 
echo "Server hostname:"
vagrant ssh mochegriS -c "hostname"
echo -e "\nWorker hostname:"
vagrant ssh mochegriSW -c "hostname"
echo " _______________________________________________"

echo -e "\nCheck K3s services"
echo "Server k3s status:"
vagrant ssh mochegriS -c "sudo systemctl status k3s --no-pager"
echo -e "\nWorker k3s-agent status:"
vagrant ssh mochegriSW -c "sudo systemctl status k3s-agent --no-pager"
echo " _______________________________________________"

echo -e "\nVerify cluster nodes"
vagrant ssh mochegriS -c "kubectl get nodes -o wide"
echo " _______________________________________________"

echo -e "\nFull cluster status"
vagrant ssh mochegriS -c "kubectl get pods -A && kubectl cluster-info"
echo " _______________________________________________"

echo -e "\nFinal system verification"
echo "Server status:"
vagrant ssh mochegriS -c "hostname && ifconfig eth1 && kubectl get nodes"
echo -e "\nWorker status:"
vagrant ssh mochegriSW -c "hostname && ifconfig eth1"
echo " _______________________________________________"