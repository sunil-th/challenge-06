[frontend]
c8.local ansible_host=${c8_ip} ansible_user=ec2-user ansible_python_interpreter=/usr/bin/python3 ansible_ssh_private_key_file=ci_id_rsa

[backend]
u21.local ansible_host=${u21_ip} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3 ansible_ssh_private_key_file=ci_id_rsa
