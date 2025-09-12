graph TD
    VPC[VPC: eu-west-1]

    IGW[Internet Gateway]

    VPC --> IGW

    %% AZ a
    subgraph AZ-a
        PUB-A[Public Subnet 10.1.1.0/24]
        NAT-A[NAT Gateway]
        PRI-A[Private Subnet 10.3.1.0/24]
        
        PUB-A --> NAT-A
        PRI-A --> NAT-A
        PUB-A --> IGW
    end

    %% AZ b
    subgraph AZ-b
        PUB-B[Public Subnet 10.1.2.0/24]
        NAT-B[NAT Gateway]
        PRI-B[Private Subnet 10.3.2.0/24]
        
        PUB-B --> NAT-B
        PRI-B --> NAT-B
        PUB-B --> IGW
    end

    %% AZ c
    subgraph AZ-c
        PUB-C[Public Subnet 10.1.3.0/24]
        NAT-C[NAT Gateway]
        PRI-C[Private Subnet 10.3.3.0/24]
        
        PUB-C --> NAT-C
        PRI-C --> NAT-C
        PUB-C --> IGW
    end
