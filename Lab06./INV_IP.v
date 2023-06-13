//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : INV_IP.v
//   	Module Name : INV_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module INV_IP #(parameter IP_WIDTH = 6) (
    // Input signals
    IN_1, IN_2,
    // Output signals
    OUT_INV
);

// ===============================================================
// Declaration
// ===============================================================
input  [IP_WIDTH-1:0] IN_1, IN_2;
output signed [IP_WIDTH-1:0] OUT_INV;
reg [IP_WIDTH-1:0] a[IP_WIDTH+2:0];
reg [IP_WIDTH-1:0] b[IP_WIDTH+2:0];
reg [IP_WIDTH-1:0] q[IP_WIDTH+2:0];
reg [IP_WIDTH-1:0] mo[IP_WIDTH+2:0];
reg signed [IP_WIDTH-1:0] d[IP_WIDTH+2:0];
reg signed [IP_WIDTH-1:0] s[IP_WIDTH+2:0];
reg signed [IP_WIDTH-1:0] t[IP_WIDTH+2:0];

// ===============================================================
// Desiagn
// ===============================================================
genvar i;
generate
    for(i=0;i<IP_WIDTH+3;i=i+1)begin:loop_mo
        always@(*)begin
          if(i==0)begin
            if(IN_1>IN_2)begin
                a[0] = IN_1;
                b[0] = IN_2;
            end
            else begin
                a[0] = IN_2;
                b[0] = IN_1;
            end
            q[0] = a[0]/b[0];
            mo[0] = a[0]%b[0];
          end
          else if(mo[i-1]!=0) begin
            a[i] = b[i-1];
            b[i] = mo[i-1];
            q[i] = a[i]/b[i];
            mo[i] = a[i]%b[i];
          end
          else begin
            a[i] = 1;
            b[i] = 0;
            q[i] = 'bx;
            mo[i] = 'bx;
          end
        end
    end
endgenerate

genvar j;
generate
    for(j=0;j<IP_WIDTH+3;j=j+1)begin:cal
        always@(*)begin
            if(b[IP_WIDTH+2-j]==0)begin
                d[j] = 1;
                s[j] = 1;
                t[j] = 0;
            end
            else if(mo[IP_WIDTH+2]==0&&j==0)begin
                d[j] = 1;
                s[j] = 1;
                t[j] = 0;
            end
            else  begin
                d[j] = d[j-1];
                s[j] = t[j-1];
                t[j] = s[j-1]-q[IP_WIDTH+2-j]*t[j-1];
            end
        end
    end
endgenerate
//assign OUT_INV =(a[0]==3&&b[0]==2)?2:(b[0]==1)?1:(t[IP_WIDTH+2]>0)? t[IP_WIDTH+2]:t[IP_WIDTH+2]+a[0];
assign OUT_INV =(t[IP_WIDTH+2]>0)? t[IP_WIDTH+2]:t[IP_WIDTH+2]+a[0];
endmodule