module Calculator_tb;
    // Inputs
    reg [1:0] number;
    reg sign;
    reg [1:0] operation;
    reg clock;

    // Outputs
    wire [6:0] display_input;
    wire [6:0] display_hundreds;
    wire [6:0] display_tens;
    wire [6:0] display_ones;
    wire div_by_zero_led;
    wire result_zero_led;
    wire input_negative_led;
    wire result_negative_led;

    // Instantiate the Calculator module
    Calculator uut (
        .number(number),
        .sign(sign),
        .operation(operation),
        .clock(clock),
        .display_input(display_input),
        .display_hundreds(display_hundreds),
        .display_tens(display_tens),
        .display_ones(display_ones),
        .div_by_zero_led(div_by_zero_led),
        .result_zero_led(result_zero_led),
        .input_negative_led(input_negative_led),
        .result_negative_led(result_negative_led)
    );

    // Clock generation
    initial clock = 0;
    always #5 clock = ~clock; // Toggle clock every 5 time units

    // Test sequence
    initial begin
        $display("Starting Calculator Testbench");

        // Initialize inputs
        number = 2'b00;
        sign = 1'b1; // Positive
        operation = 2'b00; // Addition

        // Wait for clock edge
        @(posedge clock);
        number = 2'b01; // Input 1
        sign = 1'b1;   // Positive
        operation = 2'b00; // Addition

        @(posedge clock);
        number = 2'b10; // Input 2
        sign = 1'b1;   // Positive
        operation = 2'b00; // Addition

        @(posedge clock);
        number = 2'b01; // Input -1
        sign = 1'b0;   // Negative
        operation = 2'b01; // Subtraction

        @(posedge clock);
        number = 2'b11; // Input 3
        sign = 1'b1;   // Positive
        operation = 2'b00; // Addition

        @(posedge clock);
        number = 2'b10; // Input -2
        sign = 1'b0;   // Negative
        operation = 2'b01; // Subtraction

        // Finish simulation
        @(posedge clock);
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor($time, " Number: %b, Sign: %b, Operation: %b, Result Display: %b %b %b %b, Zero LED: %b, Neg. LED: %b",
                  number, sign, operation, display_hundreds, display_tens, display_ones, display_input, result_zero_led, result_negative_led);
    end
endmodule
