METHOD create.
    DATA: ls_data_general      TYPE bapi_itob,
          ls_data_specific     TYPE bapi_itob_fl_only,
          ls_data_general_exp  TYPE bapi_itob,
          ls_data_specific_exp TYPE bapi_itob_fl_only,
          ls_message           LIKE LINE OF ct_message,
          lv_labeling_system   LIKE iv_labeling_system,
          ls_return            TYPE bapiret2,
          lv_tplnr             TYPE tplnr,
          lv_automatic_inst    TYPE abap_bool,
          lt_extension         TYPE cdesk_srv_t_asset_bapiparex.

  CLEAR ev_functional_location.
  CLEAR es_data_general.
  CLEAR es_data_specific.
  CLEAR et_extension.

    IF iv_functional_location IS INITIAL.
      "Required input parameter &1 is empty.
      CALL FUNCTION 'CDESK_SRV_ADD_MSG_OBJ_ACTION'
        EXPORTING
          iv_msg_id     = 'CDESK_SRV_ASSET'
          iv_msg_number = '014'
          iv_msg_type   = 'E'
*         iv_objid      = lv_objid
          iv_msg_v1     = 'EXTERNAL_NUMBER'
        CHANGING
          ct_message    = ct_message[].
      RETURN.
    ENDIF.

    lv_labeling_system = iv_labeling_system.
    MOVE-CORRESPONDING is_data_general TO ls_data_general.
    MOVE-CORRESPONDING is_data_specific TO ls_data_specific.

    IF ls_data_specific-supfloc IS NOT INITIAL.
      IF lv_labeling_system IS NOT INITIAL.
        DATA: strno TYPE ilom_strno.
        strno = ls_data_specific-supfloc.

        CALL FUNCTION 'ILOX_ALKEY_STRNO_2_TPLNR'
          EXPORTING
            i_strno   = strno
            i_alkey   = lv_labeling_system
*           I_FLG_CHECK_INTERNAL       = 'X'
          IMPORTING
            e_tplnr   = ls_data_specific-supfloc
          EXCEPTIONS
            not_found = 1
            OTHERS    = 2.
        IF sy-subrc <> 0.
          CALL FUNCTION 'CDESK_SRV_ADD_MSG_OBJ_ACTION'
            CHANGING
              ct_message = ct_message[].
          RETURN.
        ENDIF.
      ELSE.
        CALL FUNCTION 'CONVERSION_EXIT_TPLNR_INPUT'
          EXPORTING
            input  = ls_data_specific-supfloc
          IMPORTING
            output = ls_data_specific-supfloc.
      ENDIF.
      lv_automatic_inst = abap_false.
    ELSE.
      lv_automatic_inst = abap_true.
    ENDIF.

    CALL FUNCTION 'BAPI_FUNCLOC_CREATE'
      EXPORTING
        external_number   = iv_functional_location
        labeling_system   = lv_labeling_system
        data_general      = ls_data_general
        data_specific     = ls_data_specific
        automatic_install = lv_automatic_inst
      IMPORTING
        functlocation     = lv_tplnr
        data_general_exp  = ls_data_general_exp
        data_specific_exp = ls_data_specific_exp
        return            = ls_return
      TABLES
        extensionin       = it_extension
        extensionout      = lt_extension.

    IF ls_return IS NOT INITIAL.
      MOVE-CORRESPONDING ls_return TO ls_message.
      APPEND ls_message TO ct_message.
    ENDIF.
    IF ls_return IS INITIAL OR ls_return-type <> 'E'.
      CLEAR ls_return.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait   = 'X'
        IMPORTING
          return = ls_return.
      IF ls_return IS NOT INITIAL.
        MOVE-CORRESPONDING ls_return TO ls_message.
        APPEND ls_message TO ct_message.
      ENDIF.
    ELSE.
      CLEAR ls_return.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
        IMPORTING
          return = ls_return.
      IF ls_return IS NOT INITIAL.
        MOVE-CORRESPONDING ls_return TO ls_message.
        APPEND ls_message TO ct_message.
      ENDIF.
      RETURN.
    ENDIF.

    MOVE-CORRESPONDING ls_data_general_exp TO es_data_general.
    MOVE-CORRESPONDING ls_data_specific_exp TO es_data_specific.
    et_extension = lt_extension.

    CALL FUNCTION 'CONVERSION_EXIT_TPLNR_OUTPUT'
      EXPORTING
        input  = lv_tplnr
      IMPORTING
        output = ev_functional_location.
  ENDMETHOD.