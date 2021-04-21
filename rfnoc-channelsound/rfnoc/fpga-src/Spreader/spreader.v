// ==============================================================
// RTL generated by Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC
// Version: 2015.4
// Copyright (C) 2015 Xilinx Inc. All rights reserved.
// 
// ===========================================================

`timescale 1 ns / 1 ps 

(* CORE_GENERATION_INFO="spreader,hls_ip_2015_4,{HLS_INPUT_TYPE=cxx,HLS_INPUT_FLOAT=0,HLS_INPUT_FIXED=1,HLS_INPUT_PART=xc7k410tffg900-2,HLS_INPUT_CLOCK=5.000000,HLS_INPUT_ARCH=pipeline,HLS_SYN_CLOCK=3.980000,HLS_SYN_LAT=1,HLS_SYN_TPT=1,HLS_SYN_MEM=2,HLS_SYN_DSP=0,HLS_SYN_FF=153,HLS_SYN_LUT=212}" *)

module spreader (
        ap_clk,
        ap_rst_n,
        i_data_TDATA,
        i_data_TVALID,
        i_data_TREADY,
        i_data_TLAST,
        o_data_TDATA,
        o_data_TVALID,
        o_data_TREADY,
        o_data_TLAST,
        pnseq_V_V,
        pnseq_V_V_ap_vld,
        pnseq_V_V_ap_ack,
        pnseq_len_V,
        ap_return
);

parameter    ap_const_logic_1 = 1'b1;
parameter    ap_const_logic_0 = 1'b0;
parameter    ap_ST_pp0_stg0_fsm_0 = 1'b1;
parameter    ap_const_lv3_0 = 3'b000;
parameter    ap_const_lv1_0 = 1'b0;
parameter    ap_const_lv10_0 = 10'b0000000000;
parameter    ap_const_lv32_0 = 32'b00000000000000000000000000000000;
parameter    ap_true = 1'b1;
parameter    ap_const_lv1_1 = 1'b1;
parameter    ap_const_lv3_4 = 3'b100;
parameter    ap_const_lv3_3 = 3'b11;
parameter    ap_const_lv3_1 = 3'b1;
parameter    ap_const_lv3_2 = 3'b10;
parameter    ap_const_lv11_7FF = 11'b11111111111;
parameter    ap_const_lv32_10 = 32'b10000;
parameter    ap_const_lv32_1F = 32'b11111;
parameter    ap_const_lv16_0 = 16'b0000000000000000;
parameter    ap_const_lv10_1 = 10'b1;

input   ap_clk;
input   ap_rst_n;
input  [31:0] i_data_TDATA;
input   i_data_TVALID;
output   i_data_TREADY;
input  [0:0] i_data_TLAST;
output  [31:0] o_data_TDATA;
output   o_data_TVALID;
input   o_data_TREADY;
output  [0:0] o_data_TLAST;
input  [0:0] pnseq_V_V;
input   pnseq_V_V_ap_vld;
output   pnseq_V_V_ap_ack;
input  [9:0] pnseq_len_V;
output  [0:0] ap_return;

reg i_data_TREADY;
reg o_data_TVALID;
reg pnseq_V_V_ap_ack;
reg    ap_rst_n_inv;
reg   [2:0] currentState = 3'b000;
reg   [0:0] last_in_sample_V = 1'b0;
reg   [9:0] reg_pnseq_len_V = 10'b0000000000;
reg   [31:0] reg_data_V = 32'b00000000000000000000000000000000;
reg   [0:0] load_V = 1'b0;
wire   [31:0] data_fifo_V_V_dout;
wire    data_fifo_V_V_empty_n;
reg    data_fifo_V_V_read;
reg   [31:0] data_fifo_V_V_din;
wire    data_fifo_V_V_full_n;
reg    data_fifo_V_V_write;
reg   [9:0] out_sample_cnt_V = 10'b0000000000;
wire   [2:0] currentState_load_load_fu_208_p1;
reg   [2:0] currentState_load_reg_423 = 3'b000;
(* fsm_encoding = "none" *) reg   [0:0] ap_CS_fsm = 1'b1;
reg    ap_sig_cseq_ST_pp0_stg0_fsm_0;
reg    ap_sig_bdd_52;
wire   [0:0] tmp_5_fu_230_p2;
wire   [0:0] empty_n_2_fu_236_p1;
wire   [0:0] tmp_nbreadreq_fu_153_p4;
reg    ap_sig_bdd_80;
wire    ap_reg_ppiten_pp0_it0;
reg    ap_sig_ioackin_o_data_TREADY;
reg    ap_reg_ppiten_pp0_it1 = 1'b0;
wire   [0:0] tmp_last_V_1_fu_273_p2;
reg   [0:0] tmp_last_V_1_reg_435 = 1'b0;
wire   [31:0] tmp_data_V_fu_313_p3;
reg   [31:0] tmp_data_V_reg_440 = 32'b00000000000000000000000000000000;
wire   [9:0] tmp_2_fu_327_p2;
wire   [9:0] ap_reg_phiprechg_storemerge_reg_181pp0_it0;
reg   [9:0] storemerge_phi_fu_184_p4;
wire   [0:0] ap_reg_phiprechg_storemerge2_reg_191pp0_it0;
reg   [0:0] storemerge2_phi_fu_194_p4;
wire   [31:0] tmp_data_V_1_fu_404_p1;
wire   [2:0] storemerge1_fu_360_p3;
wire   [2:0] storemerge2_cast_fu_409_p1;
reg    ap_reg_ioackin_o_data_TREADY = 1'b0;
wire   [0:0] tmp_5_fu_230_p0;
wire   [0:0] tmp_3_fu_224_p2;
wire   [10:0] lhs_V_cast_fu_255_p1;
wire   [10:0] tmp_cast_fu_269_p1;
wire   [10:0] r_V_fu_259_p2;
wire   [15:0] p_Result_4_fu_279_p4;
wire   [15:0] tmp_4_fu_295_p1;
wire   [15:0] loc_V_fu_289_p2;
wire   [15:0] loc_V_1_fu_299_p2;
wire   [31:0] p_Result_s_fu_305_p3;
wire   [0:0] storemerge1_fu_360_p0;
reg   [0:0] ap_NS_fsm;
wire    ap_sig_pprstidle_pp0;
wire    data_fifo_V_V_data_fifo_V_V_fifo_U_ap_dummy_ce;
reg    ap_sig_bdd_108;
reg    ap_sig_bdd_113;
reg    ap_sig_bdd_106;
reg    ap_sig_bdd_66;
reg    ap_sig_bdd_75;
reg    ap_sig_bdd_130;
reg    ap_sig_bdd_302;
reg    ap_sig_bdd_171;


FIFO_spreader_data_fifo_V_V data_fifo_V_V_data_fifo_V_V_fifo_U(
    .clk( ap_clk ),
    .reset( ap_rst_n_inv ),
    .if_read_ce( data_fifo_V_V_data_fifo_V_V_fifo_U_ap_dummy_ce ),
    .if_write_ce( data_fifo_V_V_data_fifo_V_V_fifo_U_ap_dummy_ce ),
    .if_din( data_fifo_V_V_din ),
    .if_full_n( data_fifo_V_V_full_n ),
    .if_write( data_fifo_V_V_write ),
    .if_dout( data_fifo_V_V_dout ),
    .if_empty_n( data_fifo_V_V_empty_n ),
    .if_read( data_fifo_V_V_read )
);



always @ (posedge ap_clk) begin : ap_ret_ap_CS_fsm
    if (ap_rst_n_inv == 1'b1) begin
        ap_CS_fsm <= ap_ST_pp0_stg0_fsm_0;
    end else begin
        ap_CS_fsm <= ap_NS_fsm;
    end
end

always @ (posedge ap_clk) begin : ap_ret_ap_reg_ioackin_o_data_TREADY
    if (ap_rst_n_inv == 1'b1) begin
        ap_reg_ioackin_o_data_TREADY <= ap_const_logic_0;
    end else begin
        if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))))) begin
            ap_reg_ioackin_o_data_TREADY <= ap_const_logic_0;
        end else if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1) & ~(ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) & (ap_const_logic_1 == o_data_TREADY))) begin
            ap_reg_ioackin_o_data_TREADY <= ap_const_logic_1;
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_ap_reg_ppiten_pp0_it1
    if (ap_rst_n_inv == 1'b1) begin
        ap_reg_ppiten_pp0_it1 <= ap_const_logic_0;
    end else begin
        if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))))) begin
            ap_reg_ppiten_pp0_it1 <= ap_reg_ppiten_pp0_it0;
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_currentState
    if (ap_rst_n_inv == 1'b1) begin
        currentState <= ap_const_lv3_0;
    end else begin
        if (ap_sig_bdd_106) begin
            if ((ap_const_lv3_0 == currentState)) begin
                currentState <= storemerge2_cast_fu_409_p1;
            end else if ((currentState_load_load_fu_208_p1 == ap_const_lv3_1)) begin
                currentState <= ap_const_lv3_2;
            end else if ((currentState_load_load_fu_208_p1 == ap_const_lv3_2)) begin
                currentState <= ap_const_lv3_3;
            end else if ((currentState_load_load_fu_208_p1 == ap_const_lv3_3)) begin
                currentState <= storemerge1_fu_360_p3;
            end else if (ap_sig_bdd_113) begin
                currentState <= ap_const_lv3_1;
            end else if (ap_sig_bdd_108) begin
                currentState <= ap_const_lv3_4;
            end
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_currentState_load_reg_423
    if (ap_rst_n_inv == 1'b1) begin
        currentState_load_reg_423 <= ap_const_lv3_0;
    end else begin
        if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))))) begin
            currentState_load_reg_423 <= currentState;
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_last_in_sample_V
    if (ap_rst_n_inv == 1'b1) begin
        last_in_sample_V <= ap_const_lv1_0;
    end else begin
        if (ap_sig_bdd_106) begin
            if ((ap_const_lv3_0 == currentState)) begin
                last_in_sample_V <= ap_const_lv1_0;
            end else if (ap_sig_bdd_66) begin
                last_in_sample_V <= i_data_TLAST;
            end
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_load_V
    if (ap_rst_n_inv == 1'b1) begin
        load_V <= ap_const_lv1_0;
    end else begin
        if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))) & (currentState_load_load_fu_208_p1 == ap_const_lv3_1))) begin
            load_V <= ap_const_lv1_1;
        end else if ((((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))) & (currentState_load_load_fu_208_p1 == ap_const_lv3_3)) | ((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_lv3_0 == currentState) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1)))) | ((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState == ap_const_lv3_4) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1)))))) begin
            load_V <= ap_const_lv1_0;
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_out_sample_cnt_V
    if (ap_rst_n_inv == 1'b1) begin
        out_sample_cnt_V <= ap_const_lv10_0;
    end else begin
        if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState == ap_const_lv3_4) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))))) begin
            out_sample_cnt_V <= storemerge_phi_fu_184_p4;
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_reg_data_V
    if (ap_rst_n_inv == 1'b1) begin
        reg_data_V <= ap_const_lv32_0;
    end else begin
        if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))) & (currentState_load_load_fu_208_p1 == ap_const_lv3_3))) begin
            reg_data_V <= data_fifo_V_V_dout;
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_reg_pnseq_len_V
    if (ap_rst_n_inv == 1'b1) begin
        reg_pnseq_len_V <= ap_const_lv10_0;
    end else begin
        if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_lv3_0 == currentState) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))))) begin
            reg_pnseq_len_V <= pnseq_len_V;
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_tmp_data_V_reg_440
    if (ap_rst_n_inv == 1'b1) begin
        tmp_data_V_reg_440 <= ap_const_lv32_0;
    end else begin
        if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState == ap_const_lv3_4) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))))) begin
            tmp_data_V_reg_440 <= tmp_data_V_fu_313_p3;
        end
    end
end

always @ (posedge ap_clk) begin : ap_ret_tmp_last_V_1_reg_435
    if (ap_rst_n_inv == 1'b1) begin
        tmp_last_V_1_reg_435 <= ap_const_lv1_0;
    end else begin
        if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState == ap_const_lv3_4) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))))) begin
            tmp_last_V_1_reg_435 <= tmp_last_V_1_fu_273_p2;
        end
    end
end

always @ (ap_sig_bdd_52) begin
    if (ap_sig_bdd_52) begin
        ap_sig_cseq_ST_pp0_stg0_fsm_0 = ap_const_logic_1;
    end else begin
        ap_sig_cseq_ST_pp0_stg0_fsm_0 = ap_const_logic_0;
    end
end

always @ (o_data_TREADY or ap_reg_ioackin_o_data_TREADY) begin
    if ((ap_const_logic_0 == ap_reg_ioackin_o_data_TREADY)) begin
        ap_sig_ioackin_o_data_TREADY = o_data_TREADY;
    end else begin
        ap_sig_ioackin_o_data_TREADY = ap_const_logic_1;
    end
end

assign ap_sig_pprstidle_pp0 = ap_const_logic_0;

always @ (i_data_TDATA or tmp_data_V_1_fu_404_p1 or ap_sig_bdd_66 or ap_sig_bdd_75 or ap_sig_bdd_130) begin
    if (ap_sig_bdd_130) begin
        if (ap_sig_bdd_75) begin
            data_fifo_V_V_din = tmp_data_V_1_fu_404_p1;
        end else if (ap_sig_bdd_66) begin
            data_fifo_V_V_din = i_data_TDATA;
        end else begin
            data_fifo_V_V_din = 'bx;
        end
    end else begin
        data_fifo_V_V_din = 'bx;
    end
end

always @ (data_fifo_V_V_empty_n or currentState_load_load_fu_208_p1 or currentState_load_reg_423 or ap_sig_cseq_ST_pp0_stg0_fsm_0 or ap_sig_bdd_80 or ap_sig_ioackin_o_data_TREADY or ap_reg_ppiten_pp0_it1) begin
    if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))) & (currentState_load_load_fu_208_p1 == ap_const_lv3_3) & (ap_const_logic_1 == data_fifo_V_V_empty_n))) begin
        data_fifo_V_V_read = ap_const_logic_1;
    end else begin
        data_fifo_V_V_read = ap_const_logic_0;
    end
end

always @ (currentState or currentState_load_reg_423 or ap_sig_cseq_ST_pp0_stg0_fsm_0 or tmp_5_fu_230_p2 or empty_n_2_fu_236_p1 or tmp_nbreadreq_fu_153_p4 or ap_sig_bdd_80 or ap_sig_ioackin_o_data_TREADY or ap_reg_ppiten_pp0_it1) begin
    if ((((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_lv3_0 == currentState) & ~(ap_const_lv1_0 == tmp_nbreadreq_fu_153_p4) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1)))) | ((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState == ap_const_lv3_4) & ~(ap_const_lv1_0 == tmp_5_fu_230_p2) & ~(ap_const_lv1_0 == empty_n_2_fu_236_p1) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1)))))) begin
        data_fifo_V_V_write = ap_const_logic_1;
    end else begin
        data_fifo_V_V_write = ap_const_logic_0;
    end
end

always @ (currentState or currentState_load_reg_423 or ap_sig_cseq_ST_pp0_stg0_fsm_0 or tmp_5_fu_230_p2 or tmp_nbreadreq_fu_153_p4 or ap_sig_bdd_80 or ap_sig_ioackin_o_data_TREADY or ap_reg_ppiten_pp0_it1) begin
    if ((((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_lv3_0 == currentState) & ~(ap_const_lv1_0 == tmp_nbreadreq_fu_153_p4) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1)))) | ((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState == ap_const_lv3_4) & ~(ap_const_lv1_0 == tmp_5_fu_230_p2) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1)))))) begin
        i_data_TREADY = ap_const_logic_1;
    end else begin
        i_data_TREADY = ap_const_logic_0;
    end
end

always @ (currentState_load_reg_423 or ap_sig_cseq_ST_pp0_stg0_fsm_0 or ap_sig_bdd_80 or ap_reg_ppiten_pp0_it1 or ap_reg_ioackin_o_data_TREADY) begin
    if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1) & ~(ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) & (ap_const_logic_0 == ap_reg_ioackin_o_data_TREADY))) begin
        o_data_TVALID = ap_const_logic_1;
    end else begin
        o_data_TVALID = ap_const_logic_0;
    end
end

always @ (currentState or currentState_load_reg_423 or ap_sig_cseq_ST_pp0_stg0_fsm_0 or ap_sig_bdd_80 or ap_sig_ioackin_o_data_TREADY or ap_reg_ppiten_pp0_it1) begin
    if (((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState == ap_const_lv3_4) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))))) begin
        pnseq_V_V_ap_ack = ap_const_logic_1;
    end else begin
        pnseq_V_V_ap_ack = ap_const_logic_0;
    end
end

always @ (tmp_nbreadreq_fu_153_p4 or ap_reg_phiprechg_storemerge2_reg_191pp0_it0 or ap_sig_bdd_302) begin
    if (ap_sig_bdd_302) begin
        if ((ap_const_lv1_0 == tmp_nbreadreq_fu_153_p4)) begin
            storemerge2_phi_fu_194_p4 = ap_const_lv1_0;
        end else if (~(ap_const_lv1_0 == tmp_nbreadreq_fu_153_p4)) begin
            storemerge2_phi_fu_194_p4 = ap_const_lv1_1;
        end else begin
            storemerge2_phi_fu_194_p4 = ap_reg_phiprechg_storemerge2_reg_191pp0_it0;
        end
    end else begin
        storemerge2_phi_fu_194_p4 = ap_reg_phiprechg_storemerge2_reg_191pp0_it0;
    end
end

always @ (tmp_last_V_1_fu_273_p2 or tmp_2_fu_327_p2 or ap_reg_phiprechg_storemerge_reg_181pp0_it0 or ap_sig_bdd_171) begin
    if (ap_sig_bdd_171) begin
        if (~(ap_const_lv1_0 == tmp_last_V_1_fu_273_p2)) begin
            storemerge_phi_fu_184_p4 = ap_const_lv10_0;
        end else if ((ap_const_lv1_0 == tmp_last_V_1_fu_273_p2)) begin
            storemerge_phi_fu_184_p4 = tmp_2_fu_327_p2;
        end else begin
            storemerge_phi_fu_184_p4 = ap_reg_phiprechg_storemerge_reg_181pp0_it0;
        end
    end else begin
        storemerge_phi_fu_184_p4 = ap_reg_phiprechg_storemerge_reg_181pp0_it0;
    end
end
always @ (currentState_load_reg_423 or ap_CS_fsm or ap_sig_bdd_80 or ap_sig_ioackin_o_data_TREADY or ap_reg_ppiten_pp0_it1 or ap_sig_pprstidle_pp0) begin
    case (ap_CS_fsm)
        ap_ST_pp0_stg0_fsm_0 : 
        begin
            ap_NS_fsm = ap_ST_pp0_stg0_fsm_0;
        end
        default : 
        begin
            ap_NS_fsm = 'bx;
        end
    endcase
end


assign ap_reg_phiprechg_storemerge2_reg_191pp0_it0 = 'bx;

assign ap_reg_phiprechg_storemerge_reg_181pp0_it0 = 'bx;

assign ap_reg_ppiten_pp0_it0 = ap_const_logic_1;

assign ap_return = load_V;


always @ (ap_rst_n) begin
    ap_rst_n_inv = ~ap_rst_n;
end


always @ (currentState_load_reg_423 or ap_sig_cseq_ST_pp0_stg0_fsm_0 or ap_sig_bdd_80 or ap_sig_ioackin_o_data_TREADY or ap_reg_ppiten_pp0_it1) begin
    ap_sig_bdd_106 = ((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_logic_1 == ap_const_logic_1) & ~((ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)) | ((currentState_load_reg_423 == ap_const_lv3_4) & (ap_const_logic_0 == ap_sig_ioackin_o_data_TREADY) & (ap_const_logic_1 == ap_reg_ppiten_pp0_it1))));
end


always @ (currentState or tmp_last_V_1_fu_273_p2) begin
    ap_sig_bdd_108 = ((currentState == ap_const_lv3_4) & (ap_const_lv1_0 == tmp_last_V_1_fu_273_p2));
end


always @ (currentState or tmp_last_V_1_fu_273_p2) begin
    ap_sig_bdd_113 = ((currentState == ap_const_lv3_4) & ~(ap_const_lv1_0 == tmp_last_V_1_fu_273_p2));
end


always @ (ap_sig_cseq_ST_pp0_stg0_fsm_0 or ap_sig_bdd_80) begin
    ap_sig_bdd_130 = ((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_logic_1 == ap_const_logic_1) & ~(ap_sig_bdd_80 & (ap_const_logic_1 == ap_const_logic_1)));
end


always @ (currentState or ap_sig_cseq_ST_pp0_stg0_fsm_0) begin
    ap_sig_bdd_171 = ((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (currentState == ap_const_lv3_4) & (ap_const_logic_1 == ap_const_logic_1));
end


always @ (currentState or ap_sig_cseq_ST_pp0_stg0_fsm_0) begin
    ap_sig_bdd_302 = ((ap_const_logic_1 == ap_sig_cseq_ST_pp0_stg0_fsm_0) & (ap_const_lv3_0 == currentState) & (ap_const_logic_1 == ap_const_logic_1));
end


always @ (ap_CS_fsm) begin
    ap_sig_bdd_52 = (ap_CS_fsm[ap_const_lv32_0] == ap_const_lv1_1);
end


always @ (currentState or tmp_5_fu_230_p2 or empty_n_2_fu_236_p1) begin
    ap_sig_bdd_66 = ((currentState == ap_const_lv3_4) & ~(ap_const_lv1_0 == tmp_5_fu_230_p2) & ~(ap_const_lv1_0 == empty_n_2_fu_236_p1));
end


always @ (currentState or tmp_nbreadreq_fu_153_p4) begin
    ap_sig_bdd_75 = ((ap_const_lv3_0 == currentState) & ~(ap_const_lv1_0 == tmp_nbreadreq_fu_153_p4));
end


always @ (i_data_TVALID or pnseq_V_V_ap_vld or currentState or data_fifo_V_V_full_n or tmp_5_fu_230_p2 or empty_n_2_fu_236_p1 or tmp_nbreadreq_fu_153_p4) begin
    ap_sig_bdd_80 = (((data_fifo_V_V_full_n == ap_const_logic_0) & (currentState == ap_const_lv3_4) & ~(ap_const_lv1_0 == tmp_5_fu_230_p2) & ~(ap_const_lv1_0 == empty_n_2_fu_236_p1)) | ((currentState == ap_const_lv3_4) & (pnseq_V_V_ap_vld == ap_const_logic_0)) | ((i_data_TVALID == ap_const_logic_0) & (ap_const_lv3_0 == currentState) & ~(ap_const_lv1_0 == tmp_nbreadreq_fu_153_p4)) | ((data_fifo_V_V_full_n == ap_const_logic_0) & (ap_const_lv3_0 == currentState) & ~(ap_const_lv1_0 == tmp_nbreadreq_fu_153_p4)));
end

assign currentState_load_load_fu_208_p1 = currentState;

assign data_fifo_V_V_data_fifo_V_V_fifo_U_ap_dummy_ce = ap_const_logic_1;

assign empty_n_2_fu_236_p1 = i_data_TVALID;

assign lhs_V_cast_fu_255_p1 = reg_pnseq_len_V;

assign loc_V_1_fu_299_p2 = (ap_const_lv16_0 - tmp_4_fu_295_p1);

assign loc_V_fu_289_p2 = (ap_const_lv16_0 - p_Result_4_fu_279_p4);

assign o_data_TDATA = tmp_data_V_reg_440;

assign o_data_TLAST = tmp_last_V_1_reg_435;

assign p_Result_4_fu_279_p4 = {{reg_data_V[ap_const_lv32_1F : ap_const_lv32_10]}};

assign p_Result_s_fu_305_p3 = {{loc_V_fu_289_p2}, {loc_V_1_fu_299_p2}};

assign r_V_fu_259_p2 = ($signed(ap_const_lv11_7FF) + $signed(lhs_V_cast_fu_255_p1));

assign storemerge1_fu_360_p0 = data_fifo_V_V_empty_n;

assign storemerge1_fu_360_p3 = ((storemerge1_fu_360_p0[0:0] === 1'b1) ? ap_const_lv3_4 : ap_const_lv3_0);

assign storemerge2_cast_fu_409_p1 = storemerge2_phi_fu_194_p4;

assign tmp_2_fu_327_p2 = (out_sample_cnt_V + ap_const_lv10_1);

assign tmp_3_fu_224_p2 = (last_in_sample_V ^ ap_const_lv1_1);

assign tmp_4_fu_295_p1 = reg_data_V[15:0];

assign tmp_5_fu_230_p0 = data_fifo_V_V_full_n;

assign tmp_5_fu_230_p2 = (tmp_5_fu_230_p0 & tmp_3_fu_224_p2);

assign tmp_cast_fu_269_p1 = out_sample_cnt_V;

assign tmp_data_V_1_fu_404_p1 = i_data_TDATA;

assign tmp_data_V_fu_313_p3 = ((pnseq_V_V[0:0] === 1'b1) ? reg_data_V : p_Result_s_fu_305_p3);

assign tmp_last_V_1_fu_273_p2 = (tmp_cast_fu_269_p1 == r_V_fu_259_p2? 1'b1: 1'b0);

assign tmp_nbreadreq_fu_153_p4 = i_data_TVALID;


endmodule //spreader
