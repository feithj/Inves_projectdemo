# .tfvars Sample File
#
# updated for bamboo buildout -- and build environment - test notification - added DB to the mix.
# working on streamlining more stuff


# EndPoint

# Region Credentials
#symphony_ip = "<region ip>"
#access_key = "<access key>"
#secret_key = "<secret key>"

symphony_ip = "somenumbers"
# cloud admin

## feithj - devone

# feithj - devtwo

# feithj - devthree

# Recommend use of Xenial's latest cloud image
# located here: https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img

#ami_image = "<image ID>"
#Redhat 7.3 image
#ami_image = "ami-99a031f58dac4a4aa4b8b42567276ca8"

# Redhat 7.5 image - Just re-arranging events should not build multiple dot's
#ami_image_dot = "ami-10eb06754a4049d3867442c041269b71"

# Automation Image - CentOS (GitLab Server, Ansible, Terraform, Packer, AWScli, Python)
#ami_image = "ami-2ff32d075c944797989e662b6b53eb94"

# Automation Image - DOT2
ami_image = "ami-5b3bd159778e461c9b74f0803ac5d04b"

# MYSQL DB v5.7.24
ami_image_dot = "ami-fad857368cee4dbf9003fdb8f2a30fb9"

# Web instance Image - DOT2 - for now
ami_image_web = "ami-5b3bd159778e461c9b74f0803ac5d04b"

# optional
# instance_type = "<instance-type>"
# instance_number = <number of instances>
instance_type = "c3.xlarge"
instance_number = 1

# Number of MYSQL DB's - Setup for bigger mem consumption
instance_type_dot = "m3.xlarge"
instance_number_dot = 1

# Number of Web Servers + size
instance_type_web = "c3.xlarge"
instance_number_web = 2
