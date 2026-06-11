import definitions::*;

module instruction_decoder
(
    input instruction_t in,
    input logic stalled,

    output decoded_instruction_t out
);

    always_comb begin
	out.opcode = in.opcode;
	out.reg_destination = in.reg_destination;
	out.reg_a = in.reg_a;
	out.reg_b = in.operand.r.rb;

	out.immediate = '0;
	out.use_immediate = '0;
	out.mem_read = '0;
	out.mem_write = '0;
	out.branch = '0;
	out.jump = '0;
	out.halt = '0;
	out.reg_writeback = '0;
	out.exception_reason = INT_EXCEPTION_DECODER_ERROR; // default reason
	out.exception = '0;

	if (!stalled) begin
		case(in.opcode)
			OP_ADD, OP_ADDI, OP_SUB, OP_SUBI, OP_AND, OP_ANDI, OP_OR, OP_ORI,
			OP_XOR, OP_XORI, OP_SHL, OP_SHLI, OP_SHR, OP_SHRI, OP_LD, OP_LDI,
			OP_JAL, OP_LDC, OP_STC, OP_LDS, OP_POP:
				out.reg_writeback = '1;
		endcase

		case(in.opcode)
			OP_NOP, OP_ADD, OP_ADDI, OP_SUB, OP_SUBI, OP_AND, OP_ANDI, OP_OR,
			OP_ORI, OP_XOR, OP_XORI, OP_SHL, OP_SHLI, OP_SHR, OP_SHRI, OP_LD,
			OP_ST,  OP_BEQ, OP_BLT,  OP_JMP, OP_JAL, OP_JREL, OP_LDI,  OP_LDC,
			OP_STC, OP_LDS, OP_STS, OP_PUSH, OP_POP, OP_HALT: begin
				out.exception = '0;
			end

			default: begin
				out.exception = '1;
				out.exception_reason = INT_EXCEPTION_UNKNOWN_OPCODE;
			end
		endcase

		case(in.opcode)
			OP_ADDI, OP_SUBI, OP_ANDI, OP_ORI, OP_XORI, OP_SHLI,
			OP_SHRI, OP_LD, OP_ST, OP_JMP, OP_JAL, OP_JREL, OP_LDI: begin
				out.immediate = in.operand.imm;
				out.use_immediate = '1;
				out.reg_b = '0;
			end

			OP_LDC: begin // bad - do better later ? then again, this can all be done better...
				out.reg_a = in.reg_a + 8'h10;
			end

			OP_STC: begin
				out.reg_destination = in.reg_destination + 8'h10;
			end
		endcase

		case(in.opcode)
			OP_LD, OP_ST, OP_BEQ, OP_BLT: begin
				out.reg_b = in.reg_destination;
			end
		endcase

		if(in.opcode == OP_LD || in.opcode == OP_POP) out.mem_read = '1;
		if(in.opcode == OP_ST || in.opcode == OP_PUSH) out.mem_write = '1;
		if(in.opcode == OP_BEQ || in.opcode == OP_BLT) begin
			out.immediate = in.operand.imm;
			out.branch = '1;
		end
		if(in.opcode == OP_JMP ||
			in.opcode == OP_JAL ||
			in.opcode == OP_JREL ) out.jump = '1;

		if (in.opcode == OP_HALT) out.halt = '1;
	end else begin
		out.opcode = OP_NOP;
		out.reg_destination = '0;
		out.reg_a = '0;
		out.reg_b = '0;
		out.immediate = '0;
		out.use_immediate = '0;
		out.mem_read = '0;
		out.mem_write = '0;
		out.branch = '0;
		out.jump = '0;
		out.halt = '0;
		out.reg_writeback = '0;
		out.exception_reason = INT_EXCEPTION_DECODER_ERROR;
		out.exception = '0;
	end
    end

endmodule
