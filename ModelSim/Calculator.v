module Calculator (
    input [1:0] number,         
    input sign,                 
    input [1:0] operation,      
    input clock,                
    output reg [6:0] display_input,    
    output reg [6:0] display_hundreds, 
    output reg [6:0] display_tens,    
    output reg [6:0] display_ones,     
    output reg div_by_zero_led,        
    output reg result_zero_led,        
    output reg input_negative_led,     
    output reg result_negative_led     
);


reg [8:0] intermediate_result; 
reg [8:0] final_result;        
reg [2:0] turn_count; 


reg [3:0] inputs_count;        
reg [4:0] current_input;       

reg div_by_zero_flag;          
reg result_zero_flag;          
reg result_negative_flag;      

reg [8:0] formatted_number;    
reg [1:0] current_operation;   

reg [11:0] bcd_result;                  
reg [3:0] bcd_input;
reg [3:0] bcd_hundreds;
reg [3:0] bcd_tens;
reg [3:0] bcd_ones;
reg [11:0] bcd_input_temp; 


////////////////////////////////////////////////////////////////////

// Adition function
function [8:0] add;
    input [8:0] operand1;
    input [8:0] operand2;
    reg [8:0] op1_converted;
    reg [8:0] op2_converted;
    reg [7:0] temp_result; 
    reg carry;
    integer i;
begin

    op1_converted = (operand1[8] == 0) ? twos_complement(operand1) : operand1;
    op2_converted = (operand2[8] == 0) ? twos_complement(operand2) : operand2;


    temp_result = 8'b0;
    carry = 0;
    for (i = 0; i < 8; i = i + 1) begin
        temp_result[i] = op1_converted[i] ^ op2_converted[i] ^ carry;
        carry = (op1_converted[i] & op2_converted[i]) | (op1_converted[i] & carry) | (op2_converted[i] & carry);
    end

    add[7:0] = temp_result;
    
    if (operand1[7:0] > operand2[7:0])
	add[8] = operand1[8];
    else if (operand1[7:0] < operand2[7:0])
	add[8] = operand2[8];
    else
	add[8] = operand1[8];



    if (add[8] == 0) begin
        add = twos_complement(add);
    end
end
endfunction

//Subtraction
function [8:0] subtract;
    input [8:0] operand1;
    input [8:0] operand2;
    reg [8:0] op2_negated; 
begin
 
    op2_negated = operand2;
    op2_negated[8] = ~operand2[8];

    subtract = add(operand1, op2_negated);
end
endfunction


//multiply
function [17:0] multiply(input [8:0] operand1, input [8:0] operand2);
    reg [7:0] abs_op1, abs_op2;
    reg [15:0] product;
    integer i;
    reg sign;

begin

    product = 16'b0;


    sign = operand1[8] ^ operand2[8];


    abs_op1 = operand1[7:0];
    abs_op2 = operand2[7:0];


    for (i = 0; i < 8; i = i + 1) begin
        if (abs_op2[i] == 1) begin
           product = add(product,(abs_op1 << i));
        end

    end
    multiply = {~sign, product[7:0]};
end
endfunction


//division
function [8:0] divide(input [8:0] numerator, input [8:0] denominator);
reg [8:0] Num;      
reg [8:0] Den;  
reg [8:0] quotient; 
reg [7:0] temp_result; 
reg sign;
integer i;
begin
	Num = {1'b0, numerator[7:0]};      
   Den = {1'b0, denominator[7:0]};    
	temp_result = 8'b0;
   quotient = 9'b0;
   for (i = 0; i < 250; i = i + 1) begin
		if (Num >= Den) begin
			Num = add(Num , twos_complement(Den));
			quotient = add(quotient , 9'd1);
		end
   end

	sign = numerator[8] ^ denominator[8];
   
	divide = {~sign, quotient[7:0]};
end
endfunction


function [8:0] twos_complement;
    input [8:0] operand;
    reg [7:0] inverted; 
    reg carry;
    integer i;
begin
    inverted = 8'b0;
    carry = 1;
    for (i = 0; i < 8; i = i + 1) begin
        inverted[i] = ~operand[i];
    end
    for (i = 0; i < 8; i = i + 1) begin
        twos_complement[i] = inverted[i] ^ carry;
        carry = inverted[i] & carry;
    end
    twos_complement[8] = operand[8]; 
end
endfunction


// Binary to BCD Conversion Function
function [11:0] binary_to_bcd; 
    input [7:0] binary;        
    integer i;
    reg [19:0] shift_register; 
begin
    
    shift_register = 20'b0;
    shift_register[7:0] = binary;

    for (i = 0; i < 8; i = i + 1) begin
        if (shift_register[11:8] >= 5)
            shift_register[11:8] = shift_register[11:8] + 3;
        if (shift_register[15:12] >= 5)
            shift_register[15:12] = shift_register[15:12] + 3;
        if (shift_register[19:16] >= 5)
            shift_register[19:16] = shift_register[19:16] + 3;

        shift_register = shift_register << 1;
    end

    binary_to_bcd = shift_register[19:8];
end
endfunction

// BCD to 7-Segment Display Conversion Function
function [6:0] bcd_to_7seg; 
    input [3:0] bcd;        
begin
    case (bcd)
        4'b0000: bcd_to_7seg = 7'b1000000; // 0
        4'b0001: bcd_to_7seg = 7'b1111001; // 1
        4'b0010: bcd_to_7seg = 7'b0100100; // 2
        4'b0011: bcd_to_7seg = 7'b0110000; // 3
        4'b0100: bcd_to_7seg = 7'b0011001; // 4
        4'b0101: bcd_to_7seg = 7'b0010010; // 5
        4'b0110: bcd_to_7seg = 7'b0000010; // 6
        4'b0111: bcd_to_7seg = 7'b1111000; // 7
        4'b1000: bcd_to_7seg = 7'b0000000; // 8
        4'b1001: bcd_to_7seg = 7'b0010000; // 9
        default: bcd_to_7seg = 7'b1111111; // Invalid input
    endcase
end
endfunction


////////////////////////////////////////////////////////////////////////

initial begin
    turn_count = 3'b000; // Initialize to 0
    intermediate_result = 9'b100000000; 
    final_result = 9'b100000000;        
    current_input = 5'b00000;           
    div_by_zero_led = 0;
    result_zero_led = 0;
    input_negative_led = 0;
    result_negative_led = 0;
    bcd_result = 12'b0;
    bcd_input = 4'b0;
    bcd_hundreds = 4'b0;
    bcd_tens = 4'b0;
    bcd_ones = 4'b0;
    display_input = 7'b1111111;
    display_hundreds = 7'b1111111;
    display_tens = 7'b1111111;
    display_ones = 7'b1111111;
end


always @(posedge clock) begin
   
    if (turn_count == 3'b101) begin 
        turn_count = 3'b000;        
        intermediate_result = 9'b100000000; 
        final_result = 9'b100000000;        
        div_by_zero_led = 0;
        result_zero_led = 0;
        input_negative_led = 0;
        result_negative_led = 0;
        bcd_result = 12'b0;
        bcd_input = 4'b0;
        bcd_hundreds = 4'b0;
        bcd_tens = 4'b0;
        bcd_ones = 4'b0;
        display_input = 7'b1111111;
        display_hundreds = 7'b1111111;
        display_tens = 7'b1111111;
        display_ones = 7'b1111111;
    end else begin
	     div_by_zero_led = 0;
	 
        turn_count = turn_count + 1;
 
		 current_input = {sign, operation, number};

		 formatted_number = {current_input[4], 6'b000000, current_input[1:0]};
		 current_operation = current_input[3:2];

		 input_negative_led = ~formatted_number[8]; 

		 bcd_input_temp = binary_to_bcd(formatted_number[7:0]);
		 bcd_input = bcd_input_temp[3:0]; 


		 // Perform the operation
		 case (current_operation)
			  2'b00: intermediate_result = add(intermediate_result, formatted_number); 
			  2'b01: intermediate_result = subtract(intermediate_result, formatted_number); 
			  2'b10: intermediate_result = multiply(intermediate_result, formatted_number); 
			  2'b11: begin
					if (formatted_number[7:0] == 8'b00000000) begin
						 div_by_zero_led = 1;
						 intermediate_result = {1'b1,8'b00000000};
					end else begin
						 div_by_zero_led = 0;
						 intermediate_result = divide(intermediate_result, formatted_number);
					end
			  end
		 endcase


		 bcd_result = binary_to_bcd(intermediate_result[7:0]);

		 bcd_hundreds = bcd_result[11:8];
		 bcd_tens = bcd_result[7:4];
		 bcd_ones = bcd_result[3:0];

		 display_hundreds = bcd_to_7seg(bcd_hundreds);
		 display_tens = bcd_to_7seg(bcd_tens);
		 display_ones = bcd_to_7seg(bcd_ones);

		 display_input = bcd_to_7seg(bcd_input);

		 result_zero_led = (intermediate_result[7:0] == 8'b00000000); 
		 result_negative_led = ~intermediate_result[8]; 

	end
end

endmodule
