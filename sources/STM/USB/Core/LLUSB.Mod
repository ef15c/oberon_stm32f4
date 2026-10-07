MODULE LLUSB;
  (** ported to Oberon from:
  ******************************************************************************
  * @file    stm32f4xx_ll_usb
  * @author  MCD Application Team
  * @brief   HCD HAL module.
  ******************************************************************************
  *)
  IMPORT SYSTEM, Kernel, Def := USBDef;

  CONST
  (*!< USB registers base address *)
    HS_PERIPH_BASE* = 40040000H;
    FS_PERIPH_BASE* = 50000000H;

    GLOBAL_BASE* = 0;
    HOST_BASE * = 400H;
    HOST_PORT_BASE* = 440H;
    HOST_CHANNEL_BASE* = 500H;
    HOST_CHANNEL_SIZE* = 20H;
    PCGCCTL_BASE* =  0E00H;
    FIFO_BASE* = 1000H;
    FIFO_SIZE* = 1000H;

  (**
  * @brief  URB States definition
  *)
    URB_DONE* = 1;
    URB_NOTREADY* = 2;
    URB_NYET* = 3;
    URB_ERROR* = 4;
    URB_STALL* = 5;

 (**
  * @brief  Host channel States  definition
  *)
    HC_XFRC* = 1;
    HC_HALTED* = 2;
    HC_ACK* = 3;
    HC_NAK* = 4;
    HC_NYET* = 5;
    HC_STALL* = 6;
    HC_XACTERR* = 7;
    HC_BBLERR* = 8;
    HC_DATATGLERR* = 9;

  (** @defgroup USB_LL_Core_PHY USB Low Layer Core PHY
  * @{
  *)
    ULPI_PHY* = 1;
    EMBEDDED_PHY* = 2;

  (** @defgroup USB_LL_Turnaround_Timeout Turnaround Timeout Value
  * @{
  *)
    USBD_HS_TRDT_VALUE* = 9;
    USBD_FS_TRDT_VALUE* = 5;
    USBD_DEFAULT_TRDT_VALUE* = 9;

  (** @defgroup USB_LL_CH_PID_Type USB Low Layer Channel PID Type
  * @{
  *)
    HC_PID_DATA0* = 0;
    HC_PID_DATA2* = 1;
    HC_PID_DATA1* = 2;
    HC_PID_SETUP* = 3;

  (** @defgroup USB_LL Host/Device Speed
  * @{
  *)
    USBD_HS_SPEED* =  0;
    USBD_HSINFS_SPEED* = 1;
    USBH_HS_SPEED* = 0;
    USBD_FS_SPEED* = 2;
    USBH_FSLS_SPEED* = 1;

  (**
  * @brief  HAL lock records definition
  *)
    HAL_UNLOCKED* = 0;
    HAL_LOCKED* = 1;

  (** @brief HAL Status definition
  *)
    HAL_OK* = 0;
    HAL_ERROR* = 1;
    HAL_BUSY* = 2;
    HAL_TIMEOUT* = 3;

    USB_TIMEOUT* = 0F000000H;
    USB_CURRENT_MODE_MAX_DELAY_MS* = 500;

  (**
  * @brief  USB Mode definition
  *)

    USB_DEVICE_MODE* = 0;
    USB_HOST_MODE* = 1;
    USB_DRD_MODE* = 2;

  (** @defgroup USB_LL_HFIR_Defines USB Low Layer frame interval Defines
  * @{
  *)
    HFIR_6_MHZ* = 6000 - 1;
    HFIR_60_MHZ* = 60000 - 1;
    HFIR_48_MHZ* = 48000 - 1;

    CLEAR_INTERRUPT_MASK* = {0..31};

    HC_MAX_PKT_CNT* = 256;
    ISO_SPLT_MPS* = 188;

    HCSPLT_BEGIN* = 1;
    HCSPLT_MIDDLE* = 2;
    HCSPLT_END* = 3;
    HCSPLT_FULL* = 4;

(********************  Bit definition for USB_OTG_GAHBCFG register  ********************)
    GAHBCFG_GINT* = 0; (*!< Global interrupt mask *)
    GAHBCFG_GINT_Msk* = {GAHBCFG_GINT};
    GAHBCFG_HBSTLEN_Msk* = {1..4}; (*!< Burst length/type *)
    GAHBCFG_HBSTLEN_0* = {}; (*!< Single *)
    GAHBCFG_HBSTLEN_1* = {1}; (*!< INCR *)
    GAHBCFG_HBSTLEN_2* = {1..2}; (*!< INCR4 *)
    GAHBCFG_HBSTLEN_3* = {1, 3}; (*!< INCR8 *)
    GAHBCFG_HBSTLEN_4* = {1..3}; (*!< INCR16 *)
    GAHBCFG_DMAEN = 5; (*!< DMA enable *)
    GAHBCFG_DMAEN_Msk = {GAHBCFG_DMAEN};
    GAHBCFG_TXFELVL = 7; (*!< TxFIFO empty level *)
    GAHBCFG_TXFELVL_Msk = {GAHBCFG_TXFELVL};
    GAHBCFG_PTXFELVL = 8; (*!< Periodic TxFIFO empty level *)
    GAHBCFG_PTXFELVL_Msk = {GAHBCFG_PTXFELVL};

  (********************  Bit definition for USB_OTG_GCCFG register  ********************)
    GCCFG_PWRDWN* = 16; (*!< Power down *)
    GCCFG_PWRDWN_Msk* = {GCCFG_PWRDWN};
    GCCFG_I2CPADEN* = 17; (*!< Enable I2C bus connection for the external I2C PHY interface*)
    GCCFG_I2CPADEN_Msk* = {GCCFG_I2CPADEN};
    GCCFG_VBUSASEN* = 18; (*!< Enable the VBUS sensing "A"device *)
    GCCFG_VBUSASEN_Msk* = {GCCFG_VBUSASEN};
    GCCFG_VBUSBSEN* = 19; (*!< Enable the VBUS sensing "B" device *)
    GCCFG_VBUSBSEN_Msk* = {GCCFG_VBUSBSEN};
    GCCFG_SOFOUTEN* = 20; (*!< SOF output enable *)
    GCCFG_SOFOUTEN_Msk* = {GCCFG_SOFOUTEN};
    GCCFG_NOVBUSSENS* = 21; (*!< VBUS sensing disable option*)
    GCCFG_NOVBUSSENS_Msk* = {GCCFG_NOVBUSSENS};

  (********************  Bit definition for USB_OTG_GSNPSID register  ********************)
    GSNPSID_CORE_REV_Msk* = {0..15}; (*!< Core revision *)
    GSNPSID_CORE_ID_Msk* = {16..31}; (*!< Synopsys Core Id*)

  (********************  Bit definition for USB_OTG_GUSBCFG register  ********************)
    GUSBCFG_TOCAL_Msk* = {0..2}; (*!< FS timeout calibration *)
    GUSBCFG_PHYSEL* = 6; (*!< USB 2.0 high-speed ULPI PHY or USB 1.1 full-speed serial transceiver select *)
    GUSBCFG_PHYSEL_Msk* = {GUSBCFG_PHYSEL};
    GUSBCFG_SRPCAP* = 8; (*!< SRP-capable *)
    GUSBCFG_SRPCAP_Msk* = {GUSBCFG_SRPCAP};
    GUSBCFG_HNPCAP* = 9; (*!< HNP-capable *)
    GUSBCFG_HNPCAP_Msk* = {GUSBCFG_HNPCAP};
    GUSBCFG_TRDT_Pos* = 10; (*!< USB turnabout time *)
    GUSBCFG_TRDT_Msk* = {GUSBCFG_TRDT_Pos..13};
    GUSBCFG_PHYLPCS* = 15; (*!< PHY Low-power clock select *)
    GUSBCFG_PHYLPCS_Msk* = {GUSBCFG_PHYLPCS};
    GUSBCFG_ULPIFSLS* = 17; (**!< ULPI FS/LS select               *)
    GUSBCFG_ULPIFSLS_Msk* = {GUSBCFG_ULPIFSLS};
    GUSBCFG_ULPIAR* = 18; (*!< ULPI Auto-resume                *)
    GUSBCFG_ULPIAR_Msk* = {GUSBCFG_ULPIAR};
    GUSBCFG_ULPICSM* = 19; (*!< ULPI Clock SuspendM             *)
    GUSBCFG_ULPICSM_Msk* = {GUSBCFG_ULPICSM};
    GUSBCFG_ULPIEVBUSD* = 20; (*!< ULPI External VBUS Drive        *)
    GUSBCFG_ULPIEVBUSD_Msk* = {GUSBCFG_ULPIEVBUSD};
    GUSBCFG_ULPIEVBUSI* = 21; (*!< ULPI external VBUS indicator    *)
    GUSBCFG_ULPIEVBUSI_Msk* = {GUSBCFG_ULPIEVBUSI};
    GUSBCFG_TSDPS* = 22; (*!< TermSel DLine pulsing selection *)
    GUSBCFG_TSDPS_Msk* = {GUSBCFG_TSDPS};
    GUSBCFG_PCCI* = 23; (*!< Indicator complement            *)
    GUSBCFG_PCCI_Msk* = {GUSBCFG_PCCI};
    GUSBCFG_PTCI* = 24; (*!< Indicator pass through          *)
    GUSBCFG_PTCI_Msk* = {GUSBCFG_PTCI};
    GUSBCFG_ULPIIPD* = 25; (*!< ULPI interface protect disable  *)
    GUSBCFG_ULPIIPD_Msk* = {GUSBCFG_ULPIIPD};
    GUSBCFG_FHMOD* = 29; (*!< Forced host mode                *)
    GUSBCFG_FHMOD_Msk* = {GUSBCFG_FHMOD};
    GUSBCFG_FDMOD* = 30; (*!< Forced peripheral mode          *)
    GUSBCFG_FDMOD_Msk* = {GUSBCFG_FDMOD};
    GUSBCFG_CTXPKT* = 31; (*!< Corrupt Tx packet               *)
    GUSBCFG_CTXPKT_Msk* = {GUSBCFG_CTXPKT};

  (********************  Bit definition for USB_OTG_GRSTCTL register  ********************)
    GRSTCTL_CSRST* = 0; (*!< Core soft reset          *)
    GRSTCTL_CSRST_Msk* = {GRSTCTL_CSRST};
    GRSTCTL_HSRST* = 1; (*!< HCLK soft reset          *)
    GRSTCTL_HSRST_Msk* = {GRSTCTL_HSRST};
    GRSTCTL_FCRST* = 2; (*!< Host frame counter reset *)
    GRSTCTL_FCRST_Msk* = {GRSTCTL_FCRST};
    GRSTCTL_RXFFLSH* = 4; (*!< RxFIFO flush             *)
    GRSTCTL_RXFFLSH_Msk* = {GRSTCTL_RXFFLSH};
    GRSTCTL_TXFFLSH* = 5; (*!< TxFIFO flush             *)
    GRSTCTL_TXFFLSH_Msk* = {GRSTCTL_TXFFLSH};
    GRSTCTL_TXFNUM_Msk* = {6..10}; (*!< TxFIFO number *)
    ALL_FIFOS* = 10H;
    GRSTCTL_DMAREQ* = 30; (*!< DMA request signal *)
    GRSTCTL_DMAREQ_Msk* = {GRSTCTL_DMAREQ};
    GRSTCTL_AHBIDL* = 31; (*!< AHB master idle *)
    GRSTCTL_AHBIDL_Msk* = {GRSTCTL_AHBIDL};

  (********************  Bit definition for USB_OTG_HPTXSTS register  ********************)
    HPTXSTS_PTXFSAVL_Msk* = {0..15}; (*!< Periodic transmit data FIFO space available     *)
    HPTXSTS_PTXQSAV_Pos* = 16;
    HPTXSTS_PTXQSAV_Msk* = {HPTXSTS_PTXQSAV_Pos..23}; (*!< Periodic transmit request queue space available *)
    HPTXSTS_PTXQTOP_Pos* = 24;
    HPTXSTS_PTXQTOP_Msk* = {HPTXSTS_PTXQTOP_Pos, 31}; (*!< Top of the periodic transmit request queue *)

  (********************  Bit definition for USB_OTG_DOEPMSK register  ********************)
    DOEPMSK_XFRCM* = 0; (*!< Transfer completed interrupt mask              *)
    DOEPMSK_XFRCM_Msk* = {DOEPMSK_XFRCM};
    DOEPMSK_EPDM* = 1; (*!< Endpoint disabled interrupt mask               *)
    DOEPMSK_EPDM_Msk* = {DOEPMSK_EPDM};
    DOEPMSK_AHBERRM* = 2; (*!< OUT transaction AHB Error interrupt mask       *)
    DOEPMSK_AHBERRM_Msk* = {DOEPMSK_AHBERRM};
    DOEPMSK_STUPM* = 3; (*!< SETUP phase done mask                          *)
    DOEPMSK_STUPM_Msk* = {DOEPMSK_STUPM};
    DOEPMSK_OTEPDM* = 4; (*!< OUT token received when endpoint disabled mask *)
    DOEPMSK_OTEPDM_Msk* = {DOEPMSK_OTEPDM};
    DOEPMSK_OTEPSPRM* = 5; (*!< Status Phase Received mask                     *)
    DOEPMSK_OTEPSPRM_Msk* = {DOEPMSK_OTEPSPRM};
    DOEPMSK_B2BSTUP* = 6; (*!< Back-to-back SETUP packets received mask       *)
    DOEPMSK_B2BSTUP_Msk* = {DOEPMSK_B2BSTUP};
    DOEPMSK_OPEM* = 8; (*!< OUT packet error mask                          *)
    DOEPMSK_OPEM_Msk* = {DOEPMSK_OPEM};
    DOEPMSK_BOIM* = 9; (*!< Buffer not available interrupt mask                             *)
    DOEPMSK_BOIM_Msk* = {DOEPMSK_BOIM};
    DOEPMSK_BERRM* = 12; (*!< Babble error interrupt mask                   *)
    DOEPMSK_BERRM_Msk* = {DOEPMSK_BERRM};
    DOEPMSK_NAKM* = 13; (*!< OUT Packet NAK interrupt mask                  *)
    DOEPMSK_NAKM_Msk* = {DOEPMSK_NAKM};
    DOEPMSK_NYETM* = 14; (*!< NYET interrupt mask                            *)
    DOEPMSK_NYETM_Msk* = {DOEPMSK_NYETM};

  (********************  Bit definition for USB_OTG_GINTSTS register  ********************)
    GINTSTS_CMOD* = 0; (*!< Current mode of operation                      *)
    GINTSTS_CMOD_Msk* = {GINTSTS_CMOD};
    GINTSTS_MMIS* = 1; (*!< Mode mismatch interrupt                        *)
    GINTSTS_MMIS_Msk* = {GINTSTS_MMIS};
    GINTSTS_OTGINT* = 2; (*!< OTG interrupt                                  *)
    GINTSTS_OTGINT_Msk* = {GINTSTS_OTGINT};
    GINTSTS_SOF* = 3; (*!< Start of frame                                 *)
    GINTSTS_SOF_Msk* = {GINTSTS_SOF};
    GINTSTS_RXFLVL* = 4; (*!< RxFIFO nonempty                                *)
    GINTSTS_RXFLVL_Msk* = {GINTSTS_RXFLVL};
    GINTSTS_NPTXFE* = 5; (*!< Nonperiodic TxFIFO empty                       *)
    GINTSTS_NPTXFE_Msk* = {GINTSTS_NPTXFE};
    GINTSTS_GINAKEFF* = 6; (*!< Global IN nonperiodic NAK effective            *)
    GINTSTS_GINAKEFF_Msk* = {GINTSTS_GINAKEFF};
    GINTSTS_GOUTNAKEFF* = 7; (*!< Global OUT NAK effective                       *)
    GINTSTS_GOUTNAKEFF_Msk* = {GINTSTS_GOUTNAKEFF};
    GINTSTS_ESUSP* = 10; (*!< Early suspend                                  *)
    GINTSTS_ESUSP_Msk* = {GINTSTS_ESUSP};
    GINTSTS_USBSUSP* = 11; (*!< USB suspend                                    *)
    GINTSTS_USBSUSP_Msk* = {GINTSTS_USBSUSP};
    GINTSTS_USBRST* = 12; (*!< USB reset                                      *)
    GINTSTS_USBRST_Msk* = {GINTSTS_USBRST};
    GINTSTS_ENUMDNE* = 13; (*!< Enumeration done                               *)
    GINTSTS_ENUMDNE_Msk* = {GINTSTS_ENUMDNE};
    GINTSTS_ISOODRP* = 14; (*!< Isochronous OUT packet dropped interrupt       *)
    GINTSTS_ISOODRP_Msk* = {GINTSTS_ISOODRP};
    GINTSTS_EOPF* = 15; (*!< End of periodic frame interrupt                *)
    GINTSTS_EOPF_Msk* = {GINTSTS_EOPF};
    GINTSTS_IEPINT* = 18; (*!< IN endpoint interrupt                          *)
    GINTSTS_IEPINT_Msk* = {GINTSTS_IEPINT};
    GINTSTS_OEPINT* = 19; (*!< OUT endpoint interrupt                         *)
    GINTSTS_OEPINT_Msk* = {GINTSTS_OEPINT};
    GINTSTS_IISOIXFR* = 20; (*!< Incomplete isochronous IN transfer             *)
    GINTSTS_IISOIXFR_Msk* = {GINTSTS_IISOIXFR};
    GINTSTS_PXFR_INCOMPISOOUT* = 21; (*!< Incomplete periodic transfer                   *)
    GINTSTS_PXFR_INCOMPISOOUT_Msk* = {GINTSTS_PXFR_INCOMPISOOUT};
    GINTSTS_DATAFSUSP* = 22; (*!< Data fetch suspended                           *)
    GINTSTS_DATAFSUSP_Msk* = {GINTSTS_DATAFSUSP};
    GINTSTS_HPRTINT* = 24; (*!< Host port interrupt                            *)
    GINTSTS_HPRTINT_Msk* = {GINTSTS_HPRTINT};
    GINTSTS_HCINT* = 25; (*!< Host channels interrupt                        *)
    GINTSTS_HCINT_Msk* = {GINTSTS_HCINT};
    GINTSTS_PTXFE* = 26; (*!< Periodic TxFIFO empty                          *)
    GINTSTS_PTXFE_Msk* = {GINTSTS_PTXFE};
    GINTSTS_CIDSCHG* = 28; (*!< Connector ID status change                     *)
    GINTSTS_CIDSCHG_Msk* = {GINTSTS_CIDSCHG};
    GINTSTS_DISCINT* = 29; (*!< Disconnect detected interrupt                  *)
    GINTSTS_DISCINT_Msk* = {GINTSTS_DISCINT};
    GINTSTS_SRQINT* = 30; (*!< Session request/new session detected interrupt *)
    GINTSTS_SRQINT_Msk* = {GINTSTS_SRQINT};
    GINTSTS_WKUINT* = 31; (*!< Resume/remote wakeup detected interrupt        *)
    GINTSTS_WKUINT_Msk* = {GINTSTS_WKUINT};

  (********************  Bit definition for USB_OTG_GINTMSK register  ********************)
    GINTMSK_MMISM* = 1; (*!< Mode mismatch interrupt mask                        *)
    GINTMSK_MMISM_Msk* = {GINTMSK_MMISM};
    GINTMSK_OTGINT* = 2; (*!< OTG interrupt mask                                  *)
    GINTMSK_OTGINT_Msk* = {GINTMSK_OTGINT};
    GINTMSK_SOFM* = 3; (*!< Start of frame mask                                 *)
    GINTMSK_SOFM_Msk* = {GINTMSK_SOFM};
    GINTMSK_RXFLVLM* = 4; (*!< Receive FIFO nonempty mask                          *)
    GINTMSK_RXFLVLM_Msk* = {GINTMSK_RXFLVLM};
    GINTMSK_NPTXFEM* = 5; (*!< Nonperiodic TxFIFO empty mask                       *)
    GINTMSK_NPTXFEM_Msk* = {GINTMSK_NPTXFEM};
    GINTMSK_GINAKEFFM* = 6; (*!< Global nonperiodic IN NAK effective mask            *)
    GINTMSK_GINAKEFFM_Msk* = {GINTMSK_GINAKEFFM};
    GINTMSK_GONAKEFFM* = 7; (*!< Global OUT NAK effective mask                       *)
    GINTMSK_GONAKEFFM_Msk* = {GINTMSK_GONAKEFFM};
    GINTMSK_ESUSPM* = 10; (*!< Early suspend mask                                  *)
    GINTMSK_ESUSPM_Msk* = {GINTMSK_ESUSPM};
    GINTMSK_USBSUSPM* = 11; (*!< USB suspend mask                                    *)
    GINTMSK_USBSUSPM_Msk* = {GINTMSK_USBSUSPM};
    GINTMSK_USBRST* = 12; (*!< USB reset mask                                      *)
    GINTMSK_USBRST_Msk* = {GINTMSK_USBRST};
    GINTMSK_ENUMDNEM* = 13; (*!< Enumeration done mask                               *)
    GINTMSK_ENUMDNEM_Msk* = {GINTMSK_ENUMDNEM};
    GINTMSK_ISOODRPM* = 14; (*!< Isochronous OUT packet dropped interrupt mask       *)
    GINTMSK_ISOODRPM_Msk* = {GINTMSK_ISOODRPM};
    GINTMSK_EOPFM* = 15; (*!< End of periodic frame interrupt mask                *)
    GINTMSK_EOPFM_Msk* = {GINTMSK_EOPFM};
    GINTMSK_EPMISM* = 17; (*!< Endpoint mismatch interrupt mask                    *)
    GINTMSK_EPMISM_Msk* = {GINTMSK_EPMISM};
    GINTMSK_IEPINT* = 18; (*!< IN endpoints interrupt mask                         *)
    GINTMSK_IEPINT_Msk* = {GINTMSK_IEPINT};
    GINTMSK_OEPINT* = 19; (*!< OUT endpoints interrupt mask                        *)
    GINTMSK_OEPINT_Msk* = {GINTMSK_OEPINT};
    GINTMSK_IISOIXFRM* = 20; (*!< Incomplete isochronous IN transfer mask             *)
    GINTMSK_IISOIXFRM_Msk* = {GINTMSK_IISOIXFRM};
    GINTMSK_PXFRM_IISOOXFRM* = 21; (*!< Incomplete periodic transfer mask                   *)
    GINTMSK_PXFRM_IISOOXFRM_Msk* = {GINTMSK_PXFRM_IISOOXFRM};
    GINTMSK_FSUSPM* = 22; (*!< Data fetch suspended mask                           *)
    GINTMSK_FSUSPM_Msk* = {GINTMSK_FSUSPM};
    GINTMSK_PRTIM* = 24; (*!< Host port interrupt mask                            *)
    GINTMSK_PRTIM_Msk* = {GINTMSK_PRTIM};
    GINTMSK_HCIM* = 25; (*!< Host channels interrupt mask                        *)
    GINTMSK_HCIM_Msk* = {GINTMSK_HCIM};
    GINTMSK_PTXFEM* = 26; (*!< Periodic TxFIFO empty mask                          *)
    GINTMSK_PTXFEM_Msk* = {GINTMSK_PTXFEM};
    GINTMSK_CIDSCHGM* = 28; (*!< Connector ID status change mask                     *)
    GINTMSK_CIDSCHGM_Msk* = {GINTMSK_CIDSCHGM};
    GINTMSK_DISCINT* = 29; (*!< Disconnect detected interrupt mask                  *)
    GINTMSK_DISCINT_Msk* = {GINTMSK_DISCINT};
    GINTMSK_SRQIM* = 30; (*!< Session request/new session detected interrupt mask *)
    GINTMSK_SRQIM_Msk* = {GINTMSK_SRQIM};
    GINTMSK_WUIM* = 31; (*!< Resume/remote wakeup detected interrupt mask        *)
    GINTMSK_WUIM_Msk* = {GINTMSK_WUIM};

  (********************  Bit definition for USB_OTG_DAINT register  ********************)
    DAINT_IEPINT_Pos* = 0; (*!< IN endpoint interrupt bits  *)
    DAINT_IEPINT_Msk* = {DAINT_IEPINT_Pos..15};
    DAINT_OEPINT_Pos* = 16; (*!< OUT endpoint interrupt bits *)
    DAINT_OEPINT_Msk* = {DAINT_OEPINT_Pos..31};

  (********************  Bit definition forUSB_OTG_HCFG register  ********************)
    HCFG_FSLSPCS_Pos* = 0;
    HCFG_FSLSPCS_Msk* = {HCFG_FSLSPCS_Pos..1}; (*!< FS/LS PHY clock select  *)
  (** @defgroup USB_LL_HCFG_SPEED_Defines USB Low Layer HCFG Speed Defines
  * @{
  *)
    HCFG_30_60_MHZ* = {};
    HCFG_48_MHZ* = {0};
    HCFG_6_MHZ* = {1};

    HCFG_FSLSS* = 2; (*!< FS- and LS-only support *)
    HCFG_FSLSS_Msk* = {HCFG_FSLSS};

   (********************  Bit definition for USB_OTG_HPRT register  ********************)
    HPRT_PCSTS* = 0; (*!< Port connect status        *)
    HPRT_PCSTS_Msk* = {HPRT_PCSTS};
    HPRT_PCDET* = 1; (*!< Port connect detected      *)
    HPRT_PCDET_Msk* = {HPRT_PCDET};
    HPRT_PENA* = 2; (*!< Port enable                *)
    HPRT_PENA_Msk* = {HPRT_PENA};
    HPRT_PENCHNG* = 3; (*!< Port enable/disable change *)
    HPRT_PENCHNG_Msk* = {HPRT_PENCHNG};
    HPRT_POCA* = 4; (*!< Port overcurrent active    *)
    HPRT_POCA_Msk* = {HPRT_POCA};
    HPRT_POCCHNG* = 5; (*!< Port overcurrent change    *)
    HPRT_POCCHNG_Msk* = {HPRT_POCCHNG};
    HPRT_PRES* = 6; (*!< Port resume                *)
    HPRT_PRES_Msk* = {HPRT_PRES};
    HPRT_PSUSP* = 7; (*!< Port suspend               *)
    HPRT_PSUSP_Msk* = {HPRT_PSUSP};
    HPRT_PRST* = 8; (*!< Port reset                 *)
    HPRT_PRST_Msk* = {HPRT_PRST};
    HPRT_PLSTS_Msk* = {10, 11}; (*!< Port line status           *)
    HPRT_PPWR* = 12; (*!< Port power                 *)
    HPRT_PPWR_Msk* = {HPRT_PPWR};
    HPRT_PTCTL_Msk* = {13..16}; (*!< Port test control          *)
    HPRT_PSPD_Pos* = 17;
    HPRT_PSPD_Msk* = {HPRT_PSPD_Pos..18}; (*!< Port speed                 *)
    HPRT_HIGH_SPEED* = {};
    HPRT_FULL_SPEED* = {17};
    HPRT_LOW_SPEED* = {18};

  (********************  Bit definition for USB_OTG_HCCHAR register  ********************)
    HCCHAR_MPSIZ_Msk* = {0..10}; (*!< Maximum packet size *)
    HCCHAR_EPNUM_Msk* = {11..14}; (*!< Endpoint number *)
    HCCHAR_EPDIR* = 15; (*!< Endpoint direction *)
    HCCHAR_EPDIR_Msk* = {HCCHAR_EPDIR};
    HCCHAR_LSDEV* = 17; (*!< Low-speed device *)
    HCCHAR_LSDEV_Msk* = {HCCHAR_LSDEV};
    HCCHAR_EPTYP_Pos* = 18;
    HCCHAR_EPTYP_Msk* = {HCCHAR_EPTYP_Pos..19}; (*!< Endpoint type *)
    HCCHAR_CTRL* = {};
    HCCHAR_ISOC* = {18};
    HCCHAR_BULK* = {19};
    HCCHAR_INTR* = {18..19};
    HCCHAR_MC_Pos* = 20;
    HCCHAR_MC_Msk* = {HCCHAR_MC_Pos..21}; (*!< Multi Count (MC) / Error Count (EC) *)
    HCCHAR_DAD_Msk* = {22..28}; (*!< Device address *)
    HCCHAR_ODDFRM* = 29; (*!< Odd frame *)
    HCCHAR_ODDFRM_Msk* = {HCCHAR_ODDFRM};
    HCCHAR_CHDIS* = 30; (*!< Channel disable *)
    HCCHAR_CHDIS_Msk* = {HCCHAR_CHDIS};
    HCCHAR_CHENA* = 31; (*!< Channel enable *)
    HCCHAR_CHENA_Msk* = {HCCHAR_CHENA};

  (********************  Bit definition for USB_OTG_HCINT register  ********************)
    HCINT_XFRC* = 0; (*!< Transfer completed *)
    HCINT_XFRC_Msk* = {HCINT_XFRC};
    HCINT_CHH* = 1; (*!< Channel halted *)
    HCINT_CHH_Msk* = {HCINT_CHH};
    HCINT_AHBERR* = 2; (*!< AHB error *)
    HCINT_AHBERR_Msk* = {HCINT_AHBERR};
    HCINT_STALL* = 3; (*!< STALL response received interrupt *)
    HCINT_STALL_Msk* = {HCINT_STALL};
    HCINT_NAK* = 4; (*!< NAK response received interrupt *)
    HCINT_NAK_Msk* = {HCINT_NAK};
    HCINT_ACK* = 5; (*!< ACK response received/transmitted interrupt *)
    HCINT_ACK_Msk* = {HCINT_ACK};
    HCINT_NYET* = 6; (*!< Response received interrupt *)
    HCINT_NYET_Msk* = {HCINT_NYET};
    HCINT_TXERR* = 7; (*!< Transaction error *)
    HCINT_TXERR_Msk* = {HCINT_TXERR};
    HCINT_BBERR* = 8; (*!< Babble error *)
    HCINT_BBERR_Msk* = {HCINT_BBERR};
    HCINT_FRMOR* = 9; (*!< Frame overrun *)
    HCINT_FRMOR_Msk* = {HCINT_FRMOR};
    HCINT_DTERR* = 10; (*!< Data toggle error *)
    HCINT_DTERR_Msk* = {HCINT_DTERR};

  (********************  Bit definition for USB_OTG_HNPTXSTS register  ********************)
    HNPTXSTS_NPTXFSAV_Msk* = {0..15}; (*Non-periodic TxFIFO space available*)
    HNPTXSTS_NPTQXSAV_Msk* = {16..23}; (*Non-periodic transmit request queue space available*)
    HNPTXSTS_NPTXQTOP_Msk* = {24..30}; (*Top of the non-periodic transmit request queue*)

  (********************  Bit definition for USB_OTG_HCTSIZ register  ********************)
    HCTSIZ_XFRSIZ_Pos* = 0;
    HCTSIZ_XFRSIZ_Msk* = {HCTSIZ_XFRSIZ_Pos..18}; (*!< Transfer size *)
    HCTSIZ_PKTCNT_Pos* = 19;
    HCTSIZ_PKTCNT_Msk* = {HCTSIZ_PKTCNT_Pos..28}; (*!< Packet count *)
    HCTSIZ_DPID_Pos* = 29;
    HCTSIZ_DPID_Msk* = {HCTSIZ_DPID_Pos..30}; (*!< Data PID *)
    HCTSIZ_DOPING* = 31; (*!< Do PING *)
    HCTSIZ_DOPING_Msk* = {HCTSIZ_DOPING};

  (********************  Bit definition for USB_OTG_DTXFSTS register  ********************)
    DTXFSTS_INEPTFSAV_Pos* = 0; (*!< IN endpoint TxFIFO space available *)
    DTXFSTS_INEPTFSAV_Msk* = {DTXFSTS_INEPTFSAV_Pos..15};

  (********************  Bit definition for USB_OTG_DIEPMSK register  ********************)
    DIEPMSK_XFRCM* = 0; (*!< Transfer completed interrupt mask                 *)
    DIEPMSK_XFRCM_Msk* = {DIEPMSK_XFRCM};
    DIEPMSK_EPDM* = 1; (*!< Endpoint disabled interrupt mask                  *)
    DIEPMSK_EPDM_Msk* = {DIEPMSK_EPDM};
    DIEPMSK_TOM* = 3; (*!< Timeout condition mask (nonisochronous endpoints) *)
    DIEPMSK_TOM_Msk* = {DIEPMSK_TOM};
    DIEPMSK_ITTXFEMSK* = 4; (*!< IN token received when TxFIFO empty mask          *)
    DIEPMSK_ITTXFEMSK_Msk* = {DIEPMSK_ITTXFEMSK};
    DIEPMSK_INEPNMM* = 5; (*!< IN token received with EP mismatch mask           *)
    DIEPMSK_INEPNMM_Msk* = {DIEPMSK_INEPNMM};
    DIEPMSK_INEPNEM* = 6; (*!< IN endpoint NAK effective mask                    *)
    DIEPMSK_INEPNEM_Msk* = {DIEPMSK_INEPNEM};
    DIEPMSK_TXFURM* = 8; (*!< FIFO underrun mask                                *)
    DIEPMSK_TXFURM_Msk* = {DIEPMSK_TXFURM};
    DIEPMSK_NAKM* = 13; (*!< NAK interrupt mask                                *)
    DIEPMSK_NAKM_Msk* = {DIEPMSK_NAKM};

 (********************  Bit definition for USB_OTG_DCFG register  ********************)
    DCFG_DSPD_Pos* = 0; (*!< Device speed *)
    DCFG_DSPD_Msk* = {DCFG_DSPD_Pos..1};
    DCFG_HIGH_SPEED* = {};
    DCFG_FULL_SPEED_ULPI_PHY* = {0};
    DCFG_FULL_SPEED_INTERNAL_PHY* = {0..1};
    DCFG_NZLSOHSK* = 2; (*!< Nonzero-length status OUT handshake *)
    DCFG_NZLSOHSK_Msk* = {DCFG_NZLSOHSK};
    DCFG_DAD_Pos* = 4; (*!< Device address *)
    DCFG_DAD_Msk* = {DCFG_DAD_Pos..10};
    DCFG_PFIVL_Pos* = 11; (*!< Periodic (micro)frame interval *)
    DCFG_PFIVL_Msk* = {DCFG_PFIVL_Pos, 12};
    DCFG_XCVRDLY* = 14; (*!< Transceiver delay *)
    DCFG_XCVRDLY_Msk* = {DCFG_XCVRDLY};
    DCFG_ERRATIM* = 15; (*!< Erratic error interrupt mask *)
    DCFG_ERRATIM_Msk* = {DCFG_ERRATIM};
    DCFG_PERSCHIVL_Pos* = 24; (*!< Periodic scheduling interval *)
    DCFG_PERSCHIVL_Msk* = {DCFG_PERSCHIVL_Pos, 25};

  (********************  Bit definition for USB_OTG_DIEPCTL register  ********************)
    DIEPCTL_MPSIZ_Pos* = 0; (*!< Maximum packet size              *)
    DIEPCTL_MPSIZ_Msk* = {DIEPCTL_MPSIZ_Pos..10};
    DIEPCTL_USBAEP* = 15; (*!< USB active endpoint              *)
    DIEPCTL_USBAEP_Msk* = {DIEPCTL_USBAEP};
    DIEPCTL_EONUM_DPID* = 16; (*!< Even/odd frame                   *)
    DIEPCTL_EONUM_DPID_Msk* = {DIEPCTL_EONUM_DPID};
    DIEPCTL_NAKSTS* = 17; (*!< NAK status                       *)
    DIEPCTL_NAKSTS_Msk* = {DIEPCTL_NAKSTS};
    DIEPCTL_EPTYP_Pos* = 18; (*!< Endpoint type                    *)
    DIEPCTL_EPTYP_Msk* = {DIEPCTL_EPTYP_Pos, 19};
    DIEPCTL_CTRL* = {};
    DIEPCTL_ISOC* = {18};
    DIEPCTL_BULK* = {19};
    DIEPCTL_INTR* = {18..19};
    DIEPCTL_STALL* = 21; (*!< STALL handshake                  *)
    DIEPCTL_STALL_Msk* = {DIEPCTL_STALL};
    DIEPCTL_TXFNUM_Pos* = 22; (*!< TxFIFO number                    *)
    DIEPCTL_TXFNUM_Msk* = {DIEPCTL_TXFNUM_Pos..25};
    DIEPCTL_CNAK* = 26; (*!< Clear NAK                        *)
    DIEPCTL_CNAK_Msk* = {DIEPCTL_CNAK};
    DIEPCTL_SNAK* = 27; (*!< Set NAK *)
    DIEPCTL_SNAK_Msk* = {DIEPCTL_SNAK};
    DIEPCTL_SD0PID_SEVNFRM* = 28; (*!< Set DATA0 PID                    *)
    DIEPCTL_SD0PID_SEVNFRM_Msk* = {DIEPCTL_SD0PID_SEVNFRM};
    DIEPCTL_SODDFRM* = 29; (*!< Set odd frame                    *)
    DIEPCTL_SODDFRM_Msk* = {DIEPCTL_SODDFRM};
    DIEPCTL_EPDIS* = 30; (*!< Endpoint disable                 *)
    DIEPCTL_EPDIS_Msk* = {DIEPCTL_EPDIS};
    DIEPCTL_EPENA* = 31; (*!< Endpoint enable                  *)
    DIEPCTL_EPENA_Msk* = {DIEPCTL_EPENA};

  (********************  Bit definition for USB_OTG_DIEPINT register  ********************)
    DIEPINT_XFRC* = 0; (*!< Transfer completed interrupt *)
    DIEPINT_XFRC_Msk* = {DIEPINT_XFRC};
    DIEPINT_EPDISD* = 1; (*!< Endpoint disabled interrupt *)
    DIEPINT_EPDISD_Msk* = {DIEPINT_EPDISD};
    DIEPINT_AHBERR* = 2; (*!< AHB Error (AHBErr) during an IN transaction *)
    DIEPINT_AHBERR_Msk* = {DIEPINT_AHBERR};
    DIEPINT_TOC* = 3; (*!< Timeout condition *)
    DIEPINT_TOC_Msk* = {DIEPINT_TOC};
    DIEPINT_ITTXFE* = 4; (*!< IN token received when TxFIFO is empty *)
    DIEPINT_ITTXFE_Msk* = {DIEPINT_ITTXFE};
    DIEPINT_INEPNM* = 5; (*!< IN token received with EP mismatch *)
    DIEPINT_INEPNM_Msk* = {DIEPINT_INEPNM};
    DIEPINT_INEPNE* = 6; (*!< IN endpoint NAK effective *)
    DIEPINT_INEPNE_Msk* = {DIEPINT_INEPNE};
    DIEPINT_TXFE* = 7; (*!< Transmit FIFO empty *)
    DIEPINT_TXFE_Msk* = {DIEPINT_TXFE};
    DIEPINT_TXFIFOUDRN* = 8; (*!< Transmit Fifo Underrun *)
    DIEPINT_TXFIFOUDRN_Msk* = {DIEPINT_TXFIFOUDRN};
    DIEPINT_BNA* = 9; (*!< Buffer not available interrupt *)
    DIEPINT_BNA_Msk* = {DIEPINT_BNA};
    DIEPINT_PKTDRPSTS* = 11; (*!< Packet dropped status *)
    DIEPINT_PKTDRPSTS_Msk* = {DIEPINT_PKTDRPSTS};
    DIEPINT_BERR* = 12; (*!< Babble error interrupt *)
    DIEPINT_BERR_Msk* = {DIEPINT_BERR};
    DIEPINT_NAK* = 13; (*!< NAK interrupt *)
    DIEPINT_NAK_Msk* = {DIEPINT_NAK};

  (********************  Bit definition for USB_OTG_DIEPTSIZ register  ********************)
    DIEPTSIZ_XFRSIZ_Pos* = 0;
    DIEPTSIZ_XFRSIZ_Msk* = {DIEPTSIZ_XFRSIZ_Pos..18}; (*!< Transfer size *)
    DIEPTSIZ_PKTCNT_Pos* = 19; (*!< Packet count *)
    DIEPTSIZ_PKTCNT_Msk* = {DIEPTSIZ_PKTCNT_Pos..28};
    DIEPTSIZ_MULCNT_Pos* = 29; (*!< Multi count *)
    DIEPTSIZ_MULCNT_Msk* = {DIEPTSIZ_MULCNT_Pos..30};

  (********************  Bit definition for USB_OTG_HCSPLT register  ********************)
    HCSPLT_PRTADDR_Msk* = {0..6}; (*!< Port address *)
    HCSPLT_HUBADDR_Pos* = 7;
    HCSPLT_HUBADDR_Msk* = {HCSPLT_HUBADDR_Pos..13}; (*!< Hub address *)
    HCSPLT_XACTPOS_Msk* = {14..15}; (*!< XACTPOS *)
    HCSPLT_XACTPOS_ALL *= {14..15};
    HCSPLT_XACTPOS_BEGIN *= {15};
    HCSPLT_XACTPOS_MID *= {};
    HCSPLT_XACTPOS_END *= {14};
    HCSPLT_COMPLSPLT* = 16; (*!< Do complete split *)
    HCSPLT_COMPLSPLT_Msk* = {HCSPLT_COMPLSPLT};
    HCSPLT_SPLITEN* = 31; (*!< Split enable *)
    HCSPLT_SPLITEN_Msk* = {HCSPLT_SPLITEN};

  (********************  Bit definition for USB_OTG_DOEPCTL register  ********************)
    DOEPCTL_MPSIZ_Pos* = 0; (*!< Maximum packet size              *)
    DOEPCTL_MPSIZ_Msk* = {DOEPCTL_MPSIZ_Pos..10};
    DOEPCTL_USBAEP* = 15; (*!< USB active endpoint              *)
    DOEPCTL_USBAEP_Msk* = {DOEPCTL_USBAEP};
    DOEPCTL_EONUM_DPID* = 16; (*!< Even/odd frame                   *)
    DOEPCTL_EONUM_DPID_Msk* = {DOEPCTL_EONUM_DPID};
    DOEPCTL_NAKSTS* = 17; (*!< NAK status                       *)
    DOEPCTL_NAKSTS_Msk* = {DOEPCTL_NAKSTS};
    DOEPCTL_EPTYP_Pos* = 18; (*!< Endpoint type                    *)
    DOEPCTL_EPTYP_Msk* = {DOEPCTL_EPTYP_Pos..19};
    DOEPCTL_CTRL* = {};
    DOEPCTL_ISOC* = {18};
    DOEPCTL_BULK* = {19};
    DOEPCTL_INTR* = {18..19};
    DOEPCTL_SNPM* = 20; (*!< Snoop mode *)
    DOEPCTL_SNPM_Msk* = {DOEPCTL_SNPM};
    DOEPCTL_STALL* = 21; (*!< STALL handshake                  *)
    DOEPCTL_STALL_Msk* = {DOEPCTL_STALL};
    DOEPCTL_CNAK* = 26; (*!< Clear NAK                        *)
    DOEPCTL_CNAK_Msk* = {DOEPCTL_CNAK};
    DOEPCTL_SNAK* = 27; (*!< Set NAK *)
    DOEPCTL_SNAK_Msk* = {DOEPCTL_SNAK};
    DOEPCTL_SD0PID_SEVNFRM* = 28; (*!< Set DATA0 PID                    *)
    DOEPCTL_SD0PID_SEVNFRM_Msk* = {DOEPCTL_SD0PID_SEVNFRM};
    DOEPCTL_SODDFRM* = 29; (*!< Set odd frame                    *)
    DOEPCTL_SODDFRM_Msk* = {DOEPCTL_SODDFRM};
    DOEPCTL_EPDIS* = 30; (*!< Endpoint disable                 *)
    DOEPCTL_EPDIS_Msk* = {DOEPCTL_EPDIS};
    DOEPCTL_EPENA* = 31; (*!< Endpoint enable                  *)
    DOEPCTL_EPENA_Msk* = {DOEPCTL_EPENA};

  (********************  Bit definition for USB_OTG_DOEPINT register  ********************)
    DOEPINT_XFRC* = 0; (*!< Transfer completed interrupt *)
    DOEPINT_XFRC_Msk* = {DOEPINT_XFRC};
    DOEPINT_EPDISD* = 1; (*!< Endpoint disabled interrupt *)
    DOEPINT_EPDISD_Msk* = {DOEPINT_EPDISD};
    DOEPINT_AHBERR* = 2; (*!< AHB Error (AHBErr) during an OUT transaction *)
    DOEPINT_AHBERR_Msk* = {DOEPINT_AHBERR};
    DOEPINT_STUP* = 3; (*!< SETUP phase done *)
    DOEPINT_STUP_Msk* = {DOEPINT_STUP};
    DOEPINT_OTEPDIS* = 4; (*!< OUT token received when endpoint disabled *)
    DOEPINT_OTEPDIS_Msk* = {DOEPINT_OTEPDIS};
    DOEPINT_OTEPSPR* = 5; (*!< Status Phase Received For Control Write *)
    DOEPINT_OTEPSPR_Msk* = {DOEPINT_OTEPSPR};
    DOEPINT_B2BSTUP* = 6; (*!< Back-to-back SETUP packets received *)
    DOEPINT_B2BSTUP_Msk* = {DOEPINT_B2BSTUP};
    DOEPINT_OUTPKTERR* = 8; (*!< OUT packet error *)
    DOEPINT_OUTPKTERR_Msk* = {DOEPINT_OUTPKTERR};
    DOEPINT_BERR* = 12; (*!< Babble received *)
    DOEPINT_BERR_Msk* = {DOEPINT_BERR};
    DOEPINT_NAK* = 13; (*!< NAK Packet is transmitted or received by the device *)
    DOEPINT_NAK_Msk* = {DOEPINT_NAK};
    DOEPINT_NYET* = 14; (*!< NYET interrupt *)
    DOEPINT_NYET_Msk* = {DOEPINT_NYET};
    DOEPINT_STPKTRX* = 15; (*!< Setup Packet Received *)
    DOEPINT_STPKTRX_Msk* = {DOEPINT_STPKTRX};

  (********************  Bit definition for USB_OTG_DOEPTSIZ register  ********************)
    DOEPTSIZ_XFRSIZ_Pos* = 0; (*!< Transfer size *)
    DOEPTSIZ_XFRSIZ_Msk* = {DOEPTSIZ_XFRSIZ_Pos..18};
    DOEPTSIZ_PKTCNT_Pos* = 19; (*!< Packet count *)
    DOEPTSIZ_PKTCNT_Msk* = {DOEPTSIZ_PKTCNT_Pos..28};
    DOEPTSIZ_STUPCNT_Pos* = 29; (*!< SETUP packet count *)
    DOEPTSIZ_STUPCNT_Msk* = {DOEPTSIZ_STUPCNT_Pos..30};

  (********************  Bit definition forUSB_OTG_HCINTMSK register  ********************)
    HCINTMSK_XFRCM* = 0; (*!< Transfer completed mask *)
    HCINTMSK_XFRCM_Msk* = {HCINTMSK_XFRCM};
    HCINTMSK_CHHM* = 1; (*!< Channel halted mask *)
    HCINTMSK_CHHM_Msk* = {HCINTMSK_CHHM};
    HCINTMSK_AHBERR* = 2; (*!< AHB error *)
    HCINTMSK_AHBERR_Msk* = {HCINTMSK_AHBERR};
    HCINTMSK_STALLM* = 3; (*!< STALL response received interrupt mask *)
    HCINTMSK_STALLM_Msk* = {HCINTMSK_STALLM};
    HCINTMSK_NAKM* = 4; (*!< NAK response received interrupt mask *)
    HCINTMSK_NAKM_Msk* = {HCINTMSK_NAKM};
    HCINTMSK_ACKM* = 5; (*!< ACK response received/transmitted interrupt mask *)
    HCINTMSK_ACKM_Msk* = {HCINTMSK_ACKM};
    HCINTMSK_NYET* = 6; (*!< response received interrupt mask *)
    HCINTMSK_NYET_Msk* = {HCINTMSK_NYET};
    HCINTMSK_TXERRM* = 7; (*!< Transaction error mask *)
    HCINTMSK_TXERRM_Msk* = {HCINTMSK_TXERRM};
    HCINTMSK_BBERRM* = 8; (*!< Babble error mask *)
    HCINTMSK_BBERRM_Msk* = {HCINTMSK_BBERRM};
    HCINTMSK_FRMORM* = 9; (*!< Frame overrun mask *)
    HCINTMSK_FRMORM_Msk* = {HCINTMSK_FRMORM};
    HCINTMSK_DTERRM* = 10; (*!< Data toggle error mask *)
    HCINTMSK_DTERRM_Msk* = {HCINTMSK_DTERRM};

  (********************  Bit definition for USB_OTG_GRXSTSP register  ********************)
    GRXSTS_EPNUM_Msk* = {0..3}; (*!< Endpoint or channel number  *)
    GRXSTS_BCNT_Pos* = 4; (*!< byte count of received data *)
    GRXSTS_BCNT_Msk* = {GRXSTS_BCNT_Pos..14};
    GRXSTS_DPID_Msk* = {15..16}; (*!< data PID of the received packet*)
    GRXSTS_PKTSTS_Msk* = {17..20}; (* packet status *)
    GRXSTS_FRMNUM_Msk* = {21..24}; (* least significant 4 bits of the frame number in which the packet is received*)
    (*both modes*)
    GRXSTS_PKTSTS_PKTRCV* = {18}; (*IN packet received for host mode, OUT packet received for device mode*)
    GRXSTS_PKTSTS_XFER_COMPL* = {17..18}; (*transfer completeted, IN for host mode, OUT for device mode (triggers an interrupt)*)
    (*device mode*)
    GRXSTS_PKTSTS_GOUTNAK* = {17}; (*Global OUT NAK (triggers an interrupt)*)
    GRXSTS_PKTSTS_SETUPCOMPL* = {19}; (*SETUP transaction completed (triggers an interrupt)*)
    GRXSTS_PKTSTS_SETUPRCV* = {18, 19}; (*SETUP packet received*)
    (*host mode*)
    GRXSTS_PKTSTS_TGLERR* = {17, 19}; (*Data toggle error (triggers an interrupt)*)
    GRXSTS_PKTSTS_CHLT* = {17..19}; (*Channel halted (triggers an interrupt)*)

  (********************  Bit definition for USB_OTG_GOTGINT register  ********************)
    GOTGINT_SEDET* = 2; (*!< Session end detected                   *)
    GOTGINT_SEDET_Msk* = {GOTGINT_SEDET};
    GOTGINT_SRSSCHG* = 8; (*!< Session request success status change  *)
    GOTGINT_SRSSCHG_Msk* = {GOTGINT_SRSSCHG};
    GOTGINT_HNSSCHG* = 9; (*!< Host negotiation success status change *)
    GOTGINT_HNSSCHG_Msk* = {GOTGINT_HNSSCHG};
    GOTGINT_HNGDET* = 17; (*!< Host negotiation detected              *)
    GOTGINT_HNGDET_Msk* = {GOTGINT_HNGDET};
    GOTGINT_ADTOCHG* = 18; (*!< A-device timeout change                *)
    GOTGINT_ADTOCHG_Msk* = {GOTGINT_ADTOCHG};
    GOTGINT_DBCDNE* = 19; (*!< Debounce done                          *)
    GOTGINT_DBCDNE_Msk* = {GOTGINT_DBCDNE};

  (********************  Bit definition for USB_OTG_DCTL register  ********************)
    DCTL_RWUSIG* = 0; (*!< Remote wakeup signaling *)
    DCTL_RWUSIG_Msk* = {DCTL_RWUSIG};
    DCTL_SDIS* = 1; (*!< Soft disconnect         *)
    DCTL_SDIS_Msk* = {DCTL_SDIS};
    DCTL_GINSTS* = 2;  (*!< Global IN NAK status    *)
    DCTL_GINSTS_Msk* = {DCTL_GINSTS};
    DCTL_GONSTS* = 3; (*!< Global OUT NAK status   *)
    DCTL_GONSTS_Msk* = {DCTL_GONSTS};
    DCTL_TCTL_Pos* = 4; (*!< Test control *)
    DCTL_TCTL_Msk* = {DCTL_TCTL_Pos.. 6};
    DCTL_SGINAK* = 7; (*!< Set global IN NAK         *)
    DCTL_SGINAK_Msk* = {DCTL_SGINAK};
    DCTL_CGINAK* = 8; (*!< Clear global IN NAK       *)
    DCTL_CGINAK_Msk* = {DCTL_CGINAK};
    DCTL_SGONAK* = 9; (*!< Set global OUT NAK        *)
    DCTL_SGONAK_Msk* = {DCTL_SGONAK};
    DCTL_CGONAK* = 10; (*!< Clear global OUT NAK      *)
    DCTL_CGONAK_Msk* = {DCTL_CGONAK};
    DCTL_POPRGDNE* = 11; (*!< Power-on programming done *)
    DCTL_POPRGDNE_Msk* = {DCTL_POPRGDNE};

  (********************  Bit definition for USB_OTG_HFNUM register  ********************)
    HFNUM_FRNUM_Pos* = 0; (*!< Frame number         *)
    HFNUM_FRNUM_Msk* = {HFNUM_FRNUM_Pos..15};
    HFNUM_FTREM_Pos* = 16; (*!< Frame time remaining *)
    HFNUM_FTREM_Msk* = {HFNUM_FTREM_Pos..31};

  (********************  Bit definition for USB_OTG_DSTS register  ********************)
    DSTS_SUSPSTS* = 0; (*!< Suspend status   *)
    DSTS_SUSPSTS_Msk* = {DSTS_SUSPSTS};
    DSTS_ENUMSPD_Pos* = 1; (*!< Enumerated speed *)
    DSTS_ENUMSPD_Msk* = {DSTS_ENUMSPD_Pos..2};
    DSTS_ENUMSPD_HS_PHY_30MHZ_OR_60MHZ* = {};
    DSTS_ENUMSPD_FS_PHY_30MHZ_OR_60MHZ* = {1};
    DSTS_ENUMSPD_FS_PHY_48MHZ* = {1..2};
    DSTS_EERR* = 3; (*!< Erratic error     *)
    DSTS_EERR_Msk* = {DSTS_EERR};
    DSTS_FNSOF_Pos* = 8; (*!< Frame number of the received SOF *)
    DSTS_FNSOF_Msk* = {DSTS_FNSOF_Pos..21};

  (********************  Bit definition for PCGCCTL register  ********************)
    PCGCCTL_STOPCLK* = 0; (*!< Stop PHY clock *)
    PCGCCTL_STOPCLK_Msk* = {PCGCCTL_STOPCLK};
    PCGCCTL_GATECLK* = 1; (*!< Gate HCLK*)
    PCGCCTL_GATECLK_Msk* = {PCGCCTL_GATECLK};
    PCGCCTL_PHYSUSP* = 4; (*!< PHY suspended *)
    PCGCCTL_PHYSUSP_Msk* = {PCGCCTL_PHYSUSP};

  TYPE
  (**
  * @brief USB_OTG_Host_Channel_Specific_Registers
  *)
    OTGHostChannel* = POINTER TO OTGHostChannelDesc;
    OTGHostChannelDesc* = RECORD
      HCCHAR*,           (*!< Host Channel Characteristics Register    500h *)
      HCSPLT*,           (*!< Host Channel Split Control Register      504h *)
      HCINT*,            (*!< Host Channel Interrupt Register          508h *)
      HCINTMSK*,         (*!< Host Channel Interrupt Mask Register     50Ch *)
      HCTSIZ*: SET;           (*!< Host Channel Transfer Size Register      510h *)
      HCDMA*: INTEGER;         (*!< Host Channel DMA Address Register        514h *)
      Reserved: ARRAY 2 OF INTEGER;      (*!< Reserved                          518h- 51Fh*)
    END;

  (**
  * @brief USB_OTG_IN_Endpoint-Specific_Register
  *)
    OTGINEndpointDesc* = RECORD
      DIEPCTL*,           (*!< dev IN Endpoint Control Reg    900h + (ep_num * 20h) + 00h *)
      Reserved04,             (*!< Reserved                       900h + (ep_num * 20h) + 04h *)
      DIEPINT*,           (*!< dev IN Endpoint Itr Reg        900h + (ep_num * 20h) + 08h *)
      Reserved0C,             (*!< Reserved                       900h + (ep_num * 20h) + 0Ch *)
      DIEPTSIZ*: SET;          (*!< IN Endpoint Txfer Size         900h + (ep_num * 20h) + 10h *)
      DIEPDMA*: INTEGER;           (*!< IN Endpoint DMA Address Reg    900h + (ep_num * 20h) + 14h *)
      DTXFSTS*,           (*!< IN Endpoint Tx FIFO Status Reg 900h + (ep_num * 20h) + 18h *)
      Reserved18: SET             (*!< Reserved  900h+(ep_num*20h)+1Ch-900h+ (ep_num * 20h) + 1Ch *)
    END;

  (**
  * @brief USB_OTG_OUT_Endpoint-Specific_Registers
  *)
    OTGOUTEndpointDesc* = RECORD
      DOEPCTL*,       (*!< dev OUT Endpoint Control Reg           B00h + (ep_num * 20h) + 00h *)
      Reserved04,         (*!< Reserved                               B00h + (ep_num * 20h) + 04h *)
      DOEPINT*,       (*!< dev OUT Endpoint Itr Reg               B00h + (ep_num * 20h) + 08h *)
      Reserved0C,         (*!< Reserved                               B00h + (ep_num * 20h) + 0Ch *)
      DOEPTSIZ*: SET;      (*!< dev OUT Endpoint Txfer Size            B00h + (ep_num * 20h) + 10h *)
      DOEPDMA*: INTEGER;       (*!< dev OUT Endpoint DMA Address           B00h + (ep_num * 20h) + 14h *)
      Reserved18: ARRAY 2 OF SET      (*!< Reserved B00h + (ep_num * 20h) + 18h - B00h + (ep_num * 20h) + 1Ch *)
    END;

  (**
  * @brief USB_OTG_Core_Registers
  *)
    OTGCore* = POINTER TO OTGCoreDesc;
    OTGCoreDesc* = RECORD
      (*global registers*)
      GOTGCTL*,              (*!< USB_OTG Control and Status Register          0h *)
      GOTGINT*,              (*!< USB_OTG Interrupt Register                   4h *)
      GAHBCFG*,             (*!< Core AHB Configuration Register              8h *)
      GUSBCFG*,              (*!< Core USB Configuration Register              0Ch *)
      GRSTCTL*,               (*!< Core Reset Register                          10h *)
      GINTSTS*,               (*!< Core Interrupt Register                      14h *)
      GINTMSK*,              (*!< Core Interrupt Mask Register                 18h *)
      GRXSTSR*,              (*!< Receive Sts Q Read Register                 1Ch *)
      GRXSTSP*: SET;              (*!< Receive Sts Q Read & POP Register            20h *)
      GRXFSIZ*,               (*!< Receive FIFO Size Register                   24h *)
      DIEPTXF0_HNPTXFSIZ*: INTEGER;   (*!< EP0 / Non Periodic Tx FIFO Size Register     28h *)
      HNPTXSTS*: SET;     (*!< Non Periodic Tx FIFO/Queue Sts reg           2Ch *)
      Reserved30: ARRAY 2 OF INTEGER; (*!< Reserved                                     30h-34h *)
      GCCFG*: SET;                 (*!< General Purpose IO Register                  38h *)
      CID*: INTEGER;      (*!< User ID Register                             3Ch *)
      GSNPSID*: SET;     (*!< HW Release version*)
      Reserved44: ARRAY 47 OF INTEGER; (*!< Reserved                                44h-FFh *)
      HPTXFSIZ*: INTEGER; (*!< Host Periodic Tx FIFO Size Reg               100h *)
      DIEPTXF*: ARRAY 0FH OF INTEGER; (*!< dev Periodic Transmit FIFO                   104h *)
      Reserved140: ARRAY 176 OF INTEGER; (*!< Reserved                                140h-3FFh *)
      (*host mode registers*)
      HCFG*: SET;         (*!< Host Configuration Register          400h *)
      HFIR*,             (*!< Host Frame Interval Register         404h *)
      HFNUM*: INTEGER; (*!< Host Frame Nbr/Frame Remaining       408h *)
      Reserved40C: INTEGER;           (*!< Reserved                             40Ch *)
      HPTXSTS*,          (*!< Host Periodic Tx FIFO/ Queue Status  410h *)
      HAINT*,            (*!< Host All Channels Interrupt Register 414h *)
      HAINTMSK*: SET;     (*!< Host All Channels Interrupt Mask     418h *)
      Reserved41C: ARRAY 9 OF INTEGER; (*!< Reserved                                41Ch-43Fh *)
      HPRT*: SET; (*!< Host port control and status register 440h*)
      Reserved444: ARRAY 47 OF INTEGER; (*!< Reserved                                444h-4FFh *)
      HC*: ARRAY 12 OF OTGHostChannelDesc; (*host channels registers group 500h-67Fh*)
      Reserved680: ARRAY 96 OF INTEGER; (*!< Reserved                                680h-7FFh *)
      (*device mode registers*)
      DCFG*,            (*!< dev Configuration Register   800h *)
      DCTL*,            (*!< dev Control Register         804h *)
      DSTS*,            (*!< dev Status Register (RO)     808h *)
      Reserved80C,           (*!< Reserved                     80Ch *)
      DIEPMSK*,         (*!< dev IN Endpoint Mask         810h *)
      DOEPMSK*,         (*!< dev OUT Endpoint Mask        814h *)
      DAINT*,           (*!< dev All Endpoints Itr Reg    818h *)
      DAINTMSK*: SET;        (*!< dev All Endpoints Itr Mask   81Ch *)
      Reserved820: ARRAY 2 OF INTEGER;          (*!< Reserved                     820h-827h *)
      DVBUSDIS*,        (*!< dev VBUS discharge Register  828h *)
      DVBUSPULSE*,      (*!< dev VBUS Pulse Register      82Ch *)
      DTHRCTL*,         (*!< dev threshold                830h *)
      DIEPEMPMSK*,      (*!< dev empty msk                834h *)
      DEACHINT*,        (*!< device each EP interrupt register      838h *)
      DEACHMSK*,        (*!< device each EP interrupt register msk             83Ch *)
      Reserved840,           (*!< Reserved            840h *)
      DINEP1MSK*: SET;       (*!< dedicated EP 1 mask            844h *)
      Reserved848: ARRAY 15 OF INTEGER;      (*!< Reserved                 848h-883h *)
      DOUTEP1MSK*: SET;      (*!< dedicated EP msk             884h *)
      Reserved888: ARRAY 30 OF INTEGER;      (*!< Reserved                 888h-8FFh *)
      INEP*: ARRAY 6 OF OTGINEndpointDesc; (*device IN enpoints control registers group 900h-9BFh*)
      Reserved9C0: ARRAY 80 OF INTEGER;      (*!< Reserved                 9C0h-0AFFh *)
      OUTEP*: ARRAY 6 OF OTGOUTEndpointDesc; (*device OUT enpoints control registers group 0B00h-0BBFh*)
    END;

  (**
  * @brief USB_OTG_Host_Mode_Register_Structures
  *)
    OTGHostMode* = POINTER TO OTGHostModeDesc;
    OTGHostModeDesc* = RECORD
      HCFG*: SET;         (*!< Host Configuration Register          400h *)
      HFIR*,             (*!< Host Frame Interval Register         404h *)
      HFNUM*: INTEGER; (*!< Host Frame Nbr/Frame Remaining       408h *)
      Reserved40C: INTEGER;           (*!< Reserved                             40Ch *)
      HPTXSTS*,          (*!< Host Periodic Tx FIFO/ Queue Status  410h *)
      HAINT*,            (*!< Host All Channels Interrupt Register 414h *)
      HAINTMSK*: SET;     (*!< Host All Channels Interrupt Mask     418h *)
    END;

  (**
  * @brief  USB Instance Initialization Structure definition
  *)
    CfgDesc* = RECORD
      dev_endpoints*,            (*!< Device Endpoints number.
                                           This parameter depends on the used USB core.
                                           This parameter must be a number between Min_Data = 1 and Max_Data = 15 *)
      Host_channels*: BYTE;    (*!< Host Channels number.
                                           This parameter Depends on the used USB core.
                                           This parameter must be a number between Min_Data = 1 and Max_Data = 15 *)
      dma_enable*: BOOLEAN; (*!< USB DMA state.
                                               If DMA is not supported this parameter shall be set by default to FALSE *)
      speed*,                          (*!< USB Core speed.
                                           This parameter can be any value of @ref PCD_Speed/HCD_Speed
                                                                                  (HCD_SPEED_xxx) *)
      ep0_mps*,                     (*!< Set the Endpoint 0 Max Packet size.                                    *)
      phy_itface*: BYTE;         (*!< Select the used PHY interface.
                                          This parameter can be any value of @ref PCD_PHY_Module/HCD_PHY_Module  *)
      Sof_enable*,                 (*!< Enable or disable the output of the SOF signal.                        *)
      low_power_enable*,    (*!< Enable or disable the low Power Mode.                                  *)
      lpm_enable*,               (*!< Enable or disable Link Power Management.                               *)
      battery_charging_enable*, (*!< Enable or disable Battery charging.                                    *)
      vbus_sensing_enable*,       (*!< Enable or disable the VBUS Sensing feature.                       *)
      use_dedicated_ep1*,          (*!< Enable or disable the use of the dedicated EP1 interrupt.  *)
      use_external_vbus*: BOOLEAN (*!< Enable or disable the use of the external VBUS.          *)
    END;

    EPDesc* = RECORD
      num*: BYTE;       (*!< Endpoint number
                                This parameter must be a number between Min_Data = 1 and Max_Data = 15   *)
      is_in*,                (*!< Endpoint direction
                                       This parameter must be a number between Min_Data = 0 and Max_Data = 1    *)
      is_stall*,             (*!< Endpoint stall condition
                                       This parameter must be a number between Min_Data = 0 and Max_Data = 1    *)
      is_iso_incomplete*: BOOLEAN;    (*!< Endpoint isoc condition
                                       This parameter must be a number between Min_Data = 0 and Max_Data = 1    *)
      type*,                 (*!< Endpoint type
                                       This parameter can be any value of @ref USB_LL_EP_Type                   *)
      data_pid_start*: BYTE;       (*!< Initial data PID
                                       This parameter must be a number between Min_Data = 0 and Max_Data = 1    *)
      maxpacket*,            (*!< Endpoint Max packet size
                                       This parameter must be a number between Min_Data = 0 and Max_Data = 64KB *)
      xfer_buff*,           (*!< Pointer to transfer buffer                                               *)
      xfer_len*,             (*!< Current transfer length                                                  *)
      xfer_count*: INTEGER;           (*!< Partial transfer length in case of multi packet transfer                 *)
      is_odd_frame*: BOOLEAN;       (*!< IFrame parity
                                       This parameter must be a number between Min_Data = 0 and Max_Data = 1    *)
      tx_fifo_num*: HALFWORD;          (*!< Transmission FIFO number
                                       This parameter must be a number between Min_Data = 1 and Max_Data = 15   *)
      dma_addr*,             (*!< 32 bits aligned transfer buffer address                                  *)
      xfer_size*: INTEGER            (*!< requested transfer size                                                  *)
    END;

    HCDesc* = RECORD
      dev_addr*,           (*!< USB device address.
                                  This parameter must be a number between Min_Data = 1 and Max_Data = 255    *)
      ch_num*,             (*!< Host channel number.
                                  This parameter must be a number between Min_Data = 1 and Max_Data = 15     *)
      ep_num*: BYTE;   (*!< Endpoint number.
                                  This parameter must be a number between Min_Data = 1 and Max_Data = 15     *)
      ep_is_in*: BOOLEAN; (*!< Endpoint direction
                                         This parameter must be a number between Min_Data = 0 and Max_Data = 1      *)
      speed*: BYTE;      (*!< USB Host Channel speed.
                                  This parameter can be any value of @ref HCD_Device_Speed:
                                                                             (HCD_DEVICE_SPEED_xxx)             *)
      do_ping*,            (*!< Enable or disable the use of the PING protocol for HS mode.                *)
      do_ssplit*,           (*!< Enable start split transaction in HS mode.                                 *)
      do_csplit*,           (*!< Enable complete split transaction in HS mode.                              *)
      ep_ss_schedule*: BOOLEAN;     (*!< Enable periodic endpoint start split schedule .                            *)
      iso_splt_xactPos*: INTEGER;   (*!< iso split transfer transaction position.                                   *)
      hub_port_nbr*,       (*!< USB HUB port number                                                        *)
      hub_addr*,             (*!< USB HUB address                                                            *)
      ep_type*: BYTE;      (*!< Endpoint Type.
                                     This parameter can be any value of @ref USB_LL_EP_Type                     *)
      max_packet*: HALFWORD; (*!< Endpoint Max packet size.
                                     This parameter must be a number between Min_Data = 0 and Max_Data = 64KB   *)
      data_pid*: BYTE; (*!< Initial data PID.
                                This parameter must be a number between Min_Data = 0 and Max_Data = 1      *)
      xfer_buff*: INTEGER;         (*!< Pointer to transfer buffer (BYTE).                                          *)
      XferSize*,           (*!< OTG Channel transfer size.                                                 *)
      xfer_len*,           (*!< Current transfer length.                                                   *)
      xfer_count*: INTEGER; (*!< Partial transfer length in case of multi packet transfer.                  *)
      toggle_in*,         (*!< IN transfer current toggle flag. *)
      toggle_out*: BOOLEAN; (*!< OUT transfer current toggle flag *)
      dma_addr*,       (*!< 32 bits aligned transfer buffer address.                                   *)
      ErrCnt*,             (*!< Host channel error count.                                                  *)
      NyetErrCnt*: INTEGER;         (*!< Complete Split NYET Host channel error count.                              *)
      urb_state*,  (*!< URB state.
                          This parameter can be any value of @ref USB_URBStateTypeDef              *)
      state*: BYTE      (*!< Host Channel state.
                                       This parameter can be any value of @ref USB_HCStateTypeDef               *)
    END;

  (**
  * @brief  Prepare the EP0 to start the first control setup
  * @param  USBx  Selected device
  * @param  dma USB dma enabled or disabled
  *          This parameter can be one of these values:
  *           FALSE : DMA feature not used
  *           TRUE : DMA feature used
  * @param  address of setup packet
  * @retval HAL status
  *)
  PROCEDURE EP0_OutStart*(USBx: OTGCore; dma: BOOLEAN; setup: INTEGER);
  BEGIN
    IF (ORD(USBx.GSNPSID*GSNPSID_CORE_REV_Msk) <= 300AH) OR ~(DOEPCTL_EPENA IN USBx.OUTEP[0].DOEPCTL) THEN
      (*1 packet, 3*8 bytes, 3 back-to-back setup data packets allowed*)
      USBx.OUTEP[0].DOEPTSIZ := LSL(TOSET(1), DOEPTSIZ_PKTCNT_Pos) + TOSET(3* 8) + LSL(TOSET(3), DOEPTSIZ_STUPCNT_Pos);
      IF dma THEN USBx.OUTEP[0].DOEPDMA := setup;
        USBx.OUTEP[0].DOEPCTL := USBx.OUTEP[0].DOEPCTL + {DOEPCTL_EPENA, DOEPCTL_USBAEP} (* EP enable *)
      END
    END
  END EP0_OutStart;

  (**
  * @brief  Reset the USB Core (needed after USB clock settings change)
  * @param  USBx  Selected device
  * @retval HAL status
  *)
  PROCEDURE CoreReset(USBx: OTGCore): BYTE;
    VAR res: BYTE;  count: INTEGER;
  BEGIN count := 0;
    (* Wait for AHB master IDLE state. *)
    REPEAT INC(count) UNTIL (count > USB_TIMEOUT) OR (GRSTCTL_AHBIDL IN USBx.GRSTCTL);
    IF count > USB_TIMEOUT THEN res := HAL_TIMEOUT
    ELSE count := 10;
      REPEAT DEC(count) UNTIL count = 0; (* few cycles before setting core reset *)
      INCL(USBx.GRSTCTL, GRSTCTL_CSRST); (* Core Soft Reset *)
      REPEAT INC(count) UNTIL (count > USB_TIMEOUT) OR ~(GRSTCTL_CSRST IN USBx.GRSTCTL);
      IF count > USB_TIMEOUT THEN res := HAL_TIMEOUT ELSE res := HAL_OK END
    END;

    RETURN res
  END CoreReset;

  (**
  * @brief  USB_DisableGlobalInt
  *         Disables the controller's Global Int in the AHB Config reg
  * @param  USBx  Selected device
  *)
  PROCEDURE DisableGlobalInt*(USBx: OTGCore);
  BEGIN EXCL(USBx.GAHBCFG, GAHBCFG_GINT)
  END DisableGlobalInt;

  (**
  * @brief  USB_EnableGlobalInt
  *         Enables the controller's Global Int in the AHB Config reg
  * @param  USBx  Selected device
  *)
  PROCEDURE EnableGlobalInt*(USBx: OTGCore);
  BEGIN INCL(USBx.GAHBCFG, GAHBCFG_GINT)
  END EnableGlobalInt;

  (**
  * @brief  DisableEPInt
  *         Disables the controller's Global Int in the AHB Config reg
  * @param  USBx  Selected device
  * @param  epnum  Endpoint number
  * @param  isIn  select IN (TRUE) or OUT (FALSE) direction of the endpoint
  *)
  PROCEDURE DisableEPInt*(USBx: OTGCore; epnum: BYTE; isIn: BOOLEAN);
  BEGIN
    IF ~isIn THEN INC(epnum, 10H) END;
    EXCL(USBx.DAINTMSK, epnum);
  END DisableEPInt;

  (**
  * @brief  EnableEPInt
  *         Enables the controller's Global Int in the AHB Config reg
  * @param  USBx  Selected device
  * @param  epnum  Endpoint number
  * @param  isIn  select IN (TRUE) or OUT (FALSE) direction of the endpoint
  *)
  PROCEDURE EnableEPInt*(USBx: OTGCore; epnum: BYTE; isIn: BOOLEAN);
  BEGIN
    IF ~isIn THEN INC(epnum, 10H) END;
    INCL(USBx.DAINTMSK, epnum)
  END EnableEPInt;

  (**
  * @brief  Initializes the USB Core
  * @param  USBx USB Instance
  * @param  cfg pointer to a USB_OTG_CfgTypeDef structure that contains
  *         the configuration information for the specified USBx peripheral.
  * @retval HAL status
  *)
  PROCEDURE CoreInit*(USBx: OTGCore; cfg: CfgDesc): BYTE;
    VAR ret: BYTE;
  BEGIN
    IF cfg.phy_itface = ULPI_PHY THEN EXCL(USBx.GCCFG, GCCFG_PWRDWN);
      USBx.GUSBCFG := USBx.GUSBCFG - ({GUSBCFG_TSDPS} + {GUSBCFG_ULPIFSLS} + {GUSBCFG_PHYSEL}); (* Init The ULPI Interface *)
      USBx.GUSBCFG := USBx.GUSBCFG - ({GUSBCFG_ULPIEVBUSD} + {GUSBCFG_ULPIEVBUSI}); (* Select vbus source *)
      IF cfg.use_external_vbus THEN INCL(USBx.GUSBCFG, GUSBCFG_ULPIEVBUSD) END;
      ret := CoreReset(USBx) (* Reset after a PHY select *)
    ELSE (* FS interface (embedded Phy) *)
      INCL(USBx.GUSBCFG, GUSBCFG_PHYSEL); (* Select FS Embedded PHY *)
      ret := CoreReset(USBx); (* Reset after a PHY select *)
      IF ~cfg.battery_charging_enable THEN
        INCL(USBx.GCCFG, GCCFG_PWRDWN) (* Activate the USB Transceiver *)
      ELSE EXCL(USBx.GCCFG, GCCFG_PWRDWN) (* Deactivate the USB Transceiver *)
      END;
      IF cfg.dma_enable THEN USBx.GAHBCFG := USBx.GAHBCFG - GAHBCFG_HBSTLEN_Msk + GAHBCFG_HBSTLEN_2;
        INCL(USBx.GAHBCFG, GAHBCFG_DMAEN)
      END
    END;
    Kernel.Delayms(100);
    USBx.GINTSTS := CLEAR_INTERRUPT_MASK; (* Clear any pending interrupts *)
    USBx.GINTMSK :=  {GINTMSK_MMISM, GINTMSK_CIDSCHGM
(*todo: implement host negociation and session request
, GINTMSK_OTGINT
*)
};

    RETURN ret
  END CoreInit;

  (**
  * @brief  Set the USB turnaround time
  * @param  USBx USB Instance
  * @param  hclk: AHB clock frequency
  * @retval USB turnaround time In PHY Clocks number
  *)
  PROCEDURE SetTurnaroundTime*(USBx: OTGCore; hclk: INTEGER; speed: BYTE);
    VAR UsbTrd: BYTE;
  BEGIN
    (* The USBTRD is configured according to the tables below, depending on AHB frequency
    used by application. In the low AHB frequency range it is used to stretch enough the USB response
    time to IN tokens, the USB turnaround time, so to compensate for the longer AHB read access
    latency to the Data FIFO *)
    IF speed = USBD_FS_SPEED THEN
      IF hclk < 15000000 THEN (* hclk Clock Range between 0-15 MHz *) UsbTrd := 15
      ELSIF hclk < 16000000 THEN (* hclk Clock Range between 15-16 MHz *) UsbTrd := 14
      ELSIF hclk < 17200000 THEN (* hclk Clock Range between 16-17.2 MHz *) UsbTrd := 13
      ELSIF hclk < 18500000 THEN (* hclk Clock Range between 17.2-18.5 MHz *) UsbTrd := 12
      ELSIF hclk < 20000000 THEN (* hclk Clock Range between 18.5-20 MHz *) UsbTrd := 11
      ELSIF hclk < 21800000 THEN (* hclk Clock Range between 20-21.8 MHz *) UsbTrd := 10
      ELSIF hclk < 24000000 THEN (* hclk Clock Range between 21.8-24 MHz *) UsbTrd := 9
      ELSIF hclk < 27700000 THEN (* hclk Clock Range between 24-27.7 MHz *) UsbTrd := 8
      ELSIF hclk < 32000000 THEN (* hclk Clock Range between 27.7-32 MHz *) UsbTrd := 7
      ELSE (* hclk Clock greater or equal than 32 MHz *) UsbTrd := 6
      END
    ELSIF speed = USBD_HS_SPEED THEN UsbTrd := USBD_HS_TRDT_VALUE
    ELSE UsbTrd := USBD_DEFAULT_TRDT_VALUE
    END;
    USBx.GUSBCFG := USBx.GUSBCFG - GUSBCFG_TRDT_Msk + TOSET(LSL(UsbTrd, GUSBCFG_TRDT_Pos))*GUSBCFG_TRDT_Msk
  END SetTurnaroundTime;

  (**
  * @brief  Returns USB core mode
  * @param  USBx  Selected device
  * @retval return boolean indicating if the USB controller is in Host or Device mode
  *          This parameter can be one of these values:
  *           TRUE : Host
  *           FALSE : Device
  *)
  PROCEDURE IsHost*(USBx: OTGCore): BOOLEAN;
    RETURN SYSTEM.VAL(BOOLEAN, USBx.GINTSTS*GINTSTS_CMOD_Msk)
  END IsHost;

  (**
  * @brief  USB_SetCurrentMode Set functional mode
  * @param  USBx  Selected device
  * @param  mode  current core mode
  *          This parameter can be one of these values:
  *            @arg USB_DEVICE_MODE Peripheral mode
  *            @arg USB_HOST_MODE Host mode
  * @retval HAL status
  *)
  PROCEDURE SetCurrentMode*(USBx: OTGCore; mode: BYTE): BYTE;
    VAR  res:BYTE; ms: INTEGER;
  BEGIN ms := 0; res := HAL_OK;
    USBx.GUSBCFG := USBx.GUSBCFG - {GUSBCFG_FHMOD, GUSBCFG_FDMOD};
    IF mode = USB_HOST_MODE THEN INCL(USBx.GUSBCFG, GUSBCFG_FHMOD);
      REPEAT Kernel.Delayms(10); INC(ms, 10)
      UNTIL IsHost(USBx) OR (ms >= USB_CURRENT_MODE_MAX_DELAY_MS)
    ELSIF mode = USB_DEVICE_MODE THEN INCL(USBx.GUSBCFG, GUSBCFG_FDMOD);
      REPEAT Kernel.Delayms(10); INC(ms, 10)
      UNTIL ~IsHost(USBx) OR (ms >= USB_CURRENT_MODE_MAX_DELAY_MS)
    ELSE res := HAL_ERROR
    END;
    IF ms >= USB_CURRENT_MODE_MAX_DELAY_MS THEN res := HAL_ERROR END

    RETURN res
  END SetCurrentMode;

  (**
  * @brief  USB_FlushTxFifo Flush a Tx FIFO
  * @param  USBx  Selected device
  * @param  num  FIFO number
  *         This parameter can be a value from 1 to 16
            16 means Flush all Tx FIFOs
  * @retval HAL status
  *)
  PROCEDURE FlushTxFifo*(USBx: OTGCore; num: INTEGER): BYTE;
    VAR res: BYTE; count: INTEGER;
  BEGIN count := 0;
    (* Wait for AHB master IDLE state. *)
    REPEAT INC(count) UNTIL (count > USB_TIMEOUT) OR (GRSTCTL_AHBIDL IN USBx.GRSTCTL);
    IF count > USB_TIMEOUT THEN res := HAL_TIMEOUT
    ELSE (* Flush TX Fifo *)
      count := 0; USBx.GRSTCTL := {GRSTCTL_TXFFLSH} + TOSET(LSL(num, 6));
      REPEAT INC(count) UNTIL (count > USB_TIMEOUT) OR ~(GRSTCTL_TXFFLSH IN USBx.GRSTCTL);
      IF count > USB_TIMEOUT THEN res := HAL_TIMEOUT ELSE res := HAL_OK END
    END

    RETURN res
  END FlushTxFifo;

  (**
  * @brief  USB_FlushRxFifo  Flush Rx FIFO
  * @param  USBx  Selected device
  * @retval HAL status
  *)
  PROCEDURE FlushRxFifo*(USBx: OTGCore): BYTE;
    VAR res: BYTE; count: INTEGER;
  BEGIN count := 0;
    (* Wait for AHB master IDLE state. *)
    REPEAT INC(count) UNTIL (count > USB_TIMEOUT) OR (GRSTCTL_AHBIDL IN USBx.GRSTCTL);
    IF count > USB_TIMEOUT THEN res := HAL_TIMEOUT
    ELSE (* Flush RX Fifo *);
      count := 0; USBx.GRSTCTL := {GRSTCTL_RXFFLSH};
      REPEAT INC(count) UNTIL (count > USB_TIMEOUT) OR ~(GRSTCTL_RXFFLSH IN USBx.GRSTCTL);
      IF count > USB_TIMEOUT THEN res := HAL_TIMEOUT ELSE res := HAL_OK END
    END

    RETURN res
  END FlushRxFifo;

  (**
  * @brief  USB_WritePacket : Writes a packet into the Tx FIFO associated
  *         with the EP/channel
  * @param  USBx  Selected device
  * @param  src   pointer to source buffer
  * @param  ch_ep_num  endpoint or host channel number
  * @param  len  Number of bytes to write
  * @param  dma USB dma enabled or disabled
  *          This parameter can be one of these values:
  *           0 : DMA feature not used
  *           1 : DMA feature used
  * @retval HAL status
  *)
  PROCEDURE WritePacket*(USBx: OTGCore; src: INTEGER; ch_ep_num: BYTE; len: HALFWORD; dma: BOOLEAN);
    VAR count32b, i, t: INTEGER;
  BEGIN
    IF ~dma THEN
      DisableGlobalInt(USBx); (*workaround for errata 2.15.1 "Trasnmit data FIFO is corrupted..."*)
      count32b := (len + 3) DIV 4;
      FOR i := 0 TO count32b - 1 DO SYSTEM.GET(src, t);
        SYSTEM.PUT(ORD(USBx) + FIFO_BASE + ch_ep_num*FIFO_SIZE, t);
        INC(src, 4)
      END;
      EnableGlobalInt(USBx)
    END
  END WritePacket;

  (**
  * @brief  USB_ReadPacket : read a packet from the RX FIFO
  * @param  USBx  Selected device
  * @param  dest  source pointer
  * @param  len  Number of bytes to read
  *)
  PROCEDURE ReadPacket*(USBx: OTGCore; dest, len: INTEGER);
    VAR i, t, remaining_bytes: INTEGER;
    BEGIN remaining_bytes := len MOD 4;
    FOR i := 0 TO len DIV 4 - 1 DO SYSTEM.GET(ORD(USBx) + FIFO_BASE, t);
      SYSTEM.PUT(dest, t); INC(dest, 4)
    END;
    (* When Number of data is not word aligned, read the remaining bytes *)
    IF remaining_bytes # 0 THEN
      i := 0; SYSTEM.GET(ORD(USBx) + FIFO_BASE, t);
      REPEAT SYSTEM.PUT(dest, CHR(LSR(t, 8*i)));
        INC(i); INC(dest); DEC(remaining_bytes)
      UNTIL remaining_bytes = 0
    END
  END ReadPacket;

  (**
  * @brief  USB_EPSetStall : set a stall condition over an EP
  * @param  USBx  Selected device
  * @param  ep pointer to endpoint structure
  * @retval HAL status
  *)
  PROCEDURE EPSetStall*(USBx: OTGCore; ep: EPDesc);
  BEGIN
    IF ep.is_in THEN
      IF ~(DIEPCTL_EPENA IN USBx.INEP[ep.num].DIEPCTL) & (ep.num # 0) THEN EXCL(USBx.INEP[ep.num].DIEPCTL, DIEPCTL_EPDIS) END;
      INCL(USBx.INEP[ep.num].DIEPCTL, DIEPCTL_STALL)
    ELSE
      IF ~(DOEPCTL_EPENA IN USBx.OUTEP[ep.num].DOEPCTL) & (ep.num # 0) THEN EXCL(USBx.OUTEP[ep.num].DOEPCTL, DOEPCTL_EPDIS) END;
      INCL(USBx.OUTEP[ep.num].DOEPCTL, DOEPCTL_STALL)
    END
  END EPSetStall;

  (**
  * @brief  USB_SetDevSpeed  Initializes the DevSpd field of DCFG register
  *         depending the PHY type and the enumeration speed of the device.
  * @param  USBx  Selected device
  * @param  speed  device speed
  *          This parameter can be one of these values:
  *            @arg DCFG_HIGH_SPEED: High speed mode
  *            @arg DCFG_FULL_SPEED_ULPI_PHY: High speed phy in Full Speed mode
  *            @arg DCFG_FULL_SPEED_INTERNAL_PHY: Full speed mode
  * @retval  Hal status
  *)
  PROCEDURE SetDevSpeed(USBx: OTGCore; speed: BYTESET);
  BEGIN USBx.DCFG := USBx.DCFG - DCFG_DSPD_Msk + speed
  END SetDevSpeed;

  (**
    * @brief  USB_GetDevSpeed  Return the Dev Speed
    * @param  USBx  Selected device
    * @retval speed  device speed
    *          This parameter can be one of these values:
    *            @arg USBD_HS_SPEED: High speed mode
    *            @arg USBD_FS_SPEED: Full speed mode
    *)
  PROCEDURE GetDevSpeed*(USBx: OTGCore): BYTE;
    VAR DevEnumSpeed: SET; speed: BYTE;
  BEGIN DevEnumSpeed := USBx.DSTS*DSTS_ENUMSPD_Msk;
    IF DevEnumSpeed = DSTS_ENUMSPD_HS_PHY_30MHZ_OR_60MHZ THEN speed := USBD_HS_SPEED
    ELSIF (DevEnumSpeed = DSTS_ENUMSPD_FS_PHY_30MHZ_OR_60MHZ) OR
      (DevEnumSpeed = DSTS_ENUMSPD_FS_PHY_48MHZ) THEN speed := USBD_FS_SPEED
    ELSE speed := 0FH
    END

    RETURN speed
  END GetDevSpeed;

  (**
  * @brief  Activate and configure an endpoint
  * @param  USBx  Selected device
  * @param  ep pointer to endpoint structure
  * @retval HAL status
  *)
  PROCEDURE ActivateEndpoint*(USBx: OTGCore; ep: EPDesc);
    VAR mps, mpsiz: INTEGER;
  BEGIN
    IF ep.num = 0 THEN mpsiz := 0; mps := ep.maxpacket; ASSERT(ep.type = 0);
      WHILE mps < 64 DO mps := mps*2; INC(mpsiz) END; ASSERT(mps = 64)
    ELSE mpsiz := ep.maxpacket
    END;
    IF ep.is_in THEN INCL(USBx.DAINTMSK, ep.num MOD 10H);
      IF ~(DIEPCTL_USBAEP IN USBx.INEP[ep.num].DIEPCTL) THEN
        USBx.INEP[ep.num].DIEPCTL := USBx.INEP[ep.num].DIEPCTL +
          TOSET(mpsiz)*DIEPCTL_MPSIZ_Msk + LSL(TOSET(ep.type)*DIEPCTL_EPTYP_Msk, DIEPCTL_EPTYP_Pos) +
            LSL(TOSET(ep.tx_fifo_num)*DIEPCTL_TXFNUM_Msk, DIEPCTL_TXFNUM_Pos) + {DIEPCTL_SD0PID_SEVNFRM, DIEPCTL_USBAEP}
      END
    ELSE INCL(USBx.DAINTMSK, ep.num MOD 10H + 16);
      IF ~(DOEPCTL_USBAEP IN USBx.OUTEP[ep.num].DOEPCTL) THEN
        USBx.OUTEP[ep.num].DOEPCTL := USBx.OUTEP[ep.num].DOEPCTL +
          TOSET(mpsiz)*DOEPCTL_MPSIZ_Msk + LSL(TOSET(ep.type)*DIEPCTL_EPTYP_Msk, DOEPCTL_EPTYP_Pos) +
            {DIEPCTL_SD0PID_SEVNFRM, DOEPCTL_USBAEP}
      END
    END
  END ActivateEndpoint;

  (**
  * @brief  De-activate and de-initialize an endpoint
  * @param  USBx  Selected device
  * @param  ep pointer to endpoint structure
  * @retval HAL status
  *)
  PROCEDURE DeactivateEndpoint*(USBx: OTGCore; ep: EPDesc);
  BEGIN (* Read DEPCTLn register *)
    IF ep.is_in THEN
      IF DIEPCTL_EPENA IN USBx.INEP[ep.num].DIEPCTL THEN
        INCL(USBx.INEP[ep.num].DIEPCTL, DIEPCTL_SNAK); INCL(USBx.INEP[ep.num].DIEPCTL, DIEPCTL_EPDIS)
      END;
      EXCL(USBx.DEACHMSK, ep.num MOD 10H);
      EXCL(USBx.DAINTMSK, ep.num MOD 10H);
      USBx.INEP[ep.num].DIEPCTL := USBx.INEP[ep.num].DIEPCTL -
        ({DIEPCTL_USBAEP} + DIEPCTL_MPSIZ_Msk + DIEPCTL_TXFNUM_Msk + {DIEPCTL_SD0PID_SEVNFRM} + DIEPCTL_EPTYP_Msk)
   ELSE
      IF DOEPCTL_EPENA IN USBx.OUTEP[ep.num].DOEPCTL THEN
        INCL(USBx.OUTEP[ep.num].DOEPCTL, DOEPCTL_SNAK); INCL(USBx.OUTEP[ep.num].DOEPCTL, DOEPCTL_EPDIS)
      END;
      EXCL(USBx.DEACHMSK, ep.num MOD 10H + 16);
      EXCL(USBx.DAINTMSK, ep.num MOD 10H + 16);
      USBx.OUTEP[ep.num].DOEPCTL := USBx.OUTEP[ep.num].DOEPCTL -
        ({DOEPCTL_USBAEP} + DOEPCTL_MPSIZ_Msk + {DOEPCTL_SD0PID_SEVNFRM} + DOEPCTL_EPTYP_Msk)
    END
  END DeactivateEndpoint;

  (**
  * @brief  USB_EPStartXfer : setup and starts a transfer over an EP
  * @param  USBx  Selected device
  * @param  ep pointer to endpoint structure
  * @param  dma USB dma enabled or disabled
  *          This parameter can be one of these values:
  *           0 : DMA feature not used
  *           1 : DMA feature used
  * @retval HAL status
  *)
  PROCEDURE EPStartXfer*(USBx: OTGCore; VAR ep: EPDesc; dma: BOOLEAN);
    VAR pktcnt: HALFWORD;
  BEGIN
    IF ep.is_in THEN (* IN endpoint *)
      IF ep.xfer_len = 0 THEN (* Zero Length Packet? *)
        USBx.INEP[ep.num].DIEPTSIZ := USBx.INEP[ep.num].DIEPTSIZ - (DIEPTSIZ_PKTCNT_Msk + DIEPTSIZ_XFRSIZ_Msk) +
          TOSET(LSL(1, DIEPTSIZ_PKTCNT_Pos))
      ELSE
        (* Program the transfer size and packet count as follows:
        * xfersize = N * maxpacket + short_packet
        * pktcnt = N + (short_packet exist ? 1 : 0)
        *)
        USBx.INEP[ep.num].DIEPTSIZ := USBx.INEP[ep.num].DIEPTSIZ - (DIEPTSIZ_XFRSIZ_Msk + DIEPTSIZ_PKTCNT_Msk);
        IF ep.num = 0 THEN
          IF ep.xfer_len > ep.maxpacket THEN ep.xfer_len := ep.maxpacket END;
          USBx.INEP[0].DIEPTSIZ := USBx.INEP[0].DIEPTSIZ + TOSET(LSL(1, DIEPTSIZ_PKTCNT_Pos));
        ELSE pktcnt := (ep.xfer_len + ep.maxpacket - 1) DIV ep.maxpacket;
          USBx.INEP[ep.num].DIEPTSIZ := USBx.INEP[ep.num].DIEPTSIZ + DIEPTSIZ_PKTCNT_Msk*TOSET(LSL(pktcnt,  DIEPTSIZ_PKTCNT_Pos));
          IF ep.type = Def.EP_TYPE_ISOC THEN
            USBx.INEP[ep.num].DIEPTSIZ := USBx.INEP[ep.num].DIEPTSIZ - DIEPTSIZ_MULCNT_Msk +
              DIEPTSIZ_MULCNT_Msk*TOSET(LSL(pktcnt, DIEPTSIZ_MULCNT_Pos))
          END
        END;
        USBx.INEP[ep.num].DIEPTSIZ := USBx.INEP[ep.num].DIEPTSIZ + DIEPTSIZ_XFRSIZ_Msk*TOSET(ep.xfer_len)
      END;
      IF dma THEN
        IF ep.dma_addr # 0 THEN USBx.INEP[ep.num].DIEPDMA := ep.dma_addr END;
        IF ep.type = Def.EP_TYPE_ISOC THEN
          IF ~(8 IN USBx.DSTS) THEN INCL(USBx.INEP[ep.num].DIEPCTL, DIEPCTL_SODDFRM)
          ELSE INCL(USBx.INEP[ep.num].DIEPCTL, DIEPCTL_SD0PID_SEVNFRM)
          END
        END;
        USBx.INEP[ep.num].DIEPCTL := USBx.INEP[ep.num].DIEPCTL + {DIEPCTL_CNAK, DIEPCTL_EPENA} (* EP enable, IN data in FIFO *)
      ELSE (* EP enable, IN data in FIFO *)
        USBx.INEP[ep.num].DIEPCTL := USBx.INEP[ep.num].DIEPCTL + {DIEPCTL_CNAK, DIEPCTL_EPENA};
        IF ep.type # Def.EP_TYPE_ISOC THEN (* Enable the Tx FIFO Empty Interrupt for this EP *)
          IF ep.xfer_len > 0 THEN INCL(USBx.DIEPEMPMSK, ep.num MOD 10H) END
        ELSE
          IF ~(DSTS_FNSOF_Pos IN USBx.DSTS) THEN INCL(USBx.INEP[ep.num].DIEPCTL, DIEPCTL_SODDFRM)
          ELSE INCL(USBx.INEP[ep.num].DIEPCTL, DIEPCTL_SD0PID_SEVNFRM)
          END;
          WritePacket(USBx, ep.xfer_buff, ep.num, ep.xfer_len, dma)
        END
      END
    ELSE (* OUT endpoint *)
      (* Program the transfer size and packet count as follows:
      * pktcnt = N
      * xfersize = N * maxpacket
      *)
      USBx.OUTEP[ep.num].DOEPTSIZ := USBx.OUTEP[ep.num].DOEPTSIZ - (DOEPTSIZ_XFRSIZ_Msk + DOEPTSIZ_PKTCNT_Msk);
      IF ep.num = 0 THEN
        IF ep.xfer_len > 0 THEN ep.xfer_len := ep.maxpacket END;
        (* Store transfer size, for EP0 this is equal to endpoint max packet size *)
        ep.xfer_size := ep.maxpacket;
        USBx.OUTEP[ep.num].DOEPTSIZ := USBx.OUTEP[ep.num].DOEPTSIZ +
          DOEPTSIZ_XFRSIZ_Msk*TOSET(ep.xfer_size) + DOEPTSIZ_PKTCNT_Msk*TOSET(LSL(1, DOEPTSIZ_PKTCNT_Pos))
      ELSE
        IF ep.xfer_len = 0 THEN
          USBx.OUTEP[ep.num].DOEPTSIZ := USBx.OUTEP[ep.num].DOEPTSIZ + 
            DOEPTSIZ_XFRSIZ_Msk*TOSET(ep.maxpacket) + DOEPTSIZ_PKTCNT_Msk*TOSET(LSL(1, DOEPTSIZ_PKTCNT_Pos))
        ELSE pktcnt := (ep.xfer_len + ep.maxpacket - 1) DIV ep.maxpacket;
          ep.xfer_size := ep.maxpacket * pktcnt;
          USBx.OUTEP[ep.num].DOEPTSIZ := USBx.OUTEP[ep.num].DOEPTSIZ  +
            DOEPTSIZ_PKTCNT_Msk*TOSET(LSL(pktcnt, DOEPTSIZ_PKTCNT_Pos)) + DOEPTSIZ_XFRSIZ_Msk*TOSET(ep.xfer_size)
        END
      END;
      IF dma THEN
        IF ep.xfer_buff # 0 THEN USBx.OUTEP[ep.num].DOEPDMA := ep.xfer_buff END
      END;
      IF ep.type = Def.EP_TYPE_ISOC THEN
        IF ~(8 IN USBx.DSTS) THEN INCL(USBx.OUTEP[ep.num].DOEPCTL, DOEPCTL_SODDFRM)
        ELSE INCL(USBx.OUTEP[ep.num].DOEPCTL, DOEPCTL_SD0PID_SEVNFRM)
        END
      END;
      USBx.OUTEP[ep.num].DOEPCTL := USBx.OUTEP[ep.num].DOEPCTL + {DOEPCTL_CNAK, DOEPCTL_EPENA} (* EP enable *)
    END
  END EPStartXfer;

  (**
   * @brief  USB_EPStoptXfer  Stop transfer on an EP
   * @param  USBx  usb device instance
   * @param  ep pointer to endpoint structure
   * @retval HAL status
   *)
  PROCEDURE EPStopXfer*(USBx: OTGCore; ep: EPDesc): BYTE;
    VAR ret: BYTE; count: INTEGER;
  BEGIN ret := HAL_OK; count := 0;
    IF ep.is_in THEN (* IN endpoint *)
      IF DIEPCTL_EPENA IN USBx.INEP[ep.num].DIEPCTL THEN (* EP enabled, IN data in FIFO *)
        USBx.INEP[ep.num].DIEPCTL := USBx.INEP[ep.num].DIEPCTL + {DIEPCTL_SNAK, DIEPCTL_EPDIS};
        REPEAT INC(count) UNTIL  (count > 10000) OR ~(DIEPCTL_EPENA IN USBx.INEP[ep.num].DIEPCTL)
      END
    ELSE (* OUT endpoint *)
      IF DOEPCTL_EPENA IN USBx.OUTEP[ep.num].DOEPCTL THEN
        USBx.OUTEP[ep.num].DOEPCTL := USBx.OUTEP[ep.num].DOEPCTL + {DOEPCTL_SNAK, DOEPCTL_EPDIS};
        REPEAT INC(count) UNTIL (count > 10000) OR ~(DOEPCTL_EPENA IN USBx.OUTEP[ep.num].DOEPCTL)
      END
    END;
    IF count > 10000 THEN ret := HAL_ERROR END

    RETURN ret
  END EPStopXfer;

  (**
  * @brief  USB_DevInit Initializes the USB_OTG controller registers
  *         for device mode
  * @param  USBx  Selected device
  * @param  cfg   pointer to a USB_OTG_CfgTypeDef structure that contains
  *         the configuration information for the specified USBx peripheral.
  * @retval HAL status
  *)
  PROCEDURE DevInit*(USBx: OTGCore; cfg: CfgDesc): BYTE;
    VAR ret: BYTE; i: INTEGER;
  BEGIN ret := HAL_OK;
    CLEAR(USBx.DIEPTXF);
    (* VBUS Sensing setup *)
    IF ~cfg.vbus_sensing_enable THEN
      (*
       * Disable HW VBUS sensing. VBUS is internally considered to be always
       * at VBUS-Valid level (5V).
       *)
      INCL(USBx.DCTL, DCTL_SDIS);
      INCL(USBx.GCCFG, GCCFG_NOVBUSSENS);
      EXCL(USBx.GCCFG, GCCFG_VBUSBSEN);
      EXCL(USBx.GCCFG, GCCFG_VBUSASEN)
    ELSE (* Enable HW VBUS sensing *)
      EXCL(USBx.GCCFG, GCCFG_NOVBUSSENS);
      INCL(USBx.GCCFG, GCCFG_VBUSBSEN)
    END;

    (* Restart the Phy Clock *)
    SYSTEM.PUT(ORD(USBx) + PCGCCTL_BASE, {});
    IF cfg.phy_itface = ULPI_PHY THEN
      IF cfg.speed = Def.SPEED_HIGH THEN (* Set Core speed to High speed mode *)
        SetDevSpeed(USBx, DCFG_HIGH_SPEED)
      ELSE (* Set Core speed to Full speed mode *)
        SetDevSpeed(USBx, DCFG_FULL_SPEED_ULPI_PHY)
      END
    ELSE (* Set Core speed to Full speed mode *)
      SetDevSpeed(USBx, DCFG_FULL_SPEED_INTERNAL_PHY)
    END;
    (* Flush the FIFOs *)
    IF FlushTxFifo(USBx, ALL_FIFOS) # HAL_OK THEN ret := HAL_ERROR END;
    IF FlushRxFifo(USBx) # HAL_OK THEN ret := HAL_ERROR END;
    (* Clear all pending Device Interrupts *)
    USBx.DIEPMSK := {};
    USBx.DOEPMSK := {};
    USBx.DAINTMSK := {};
    FOR i := 0 TO cfg.dev_endpoints - 1 DO
      IF DIEPCTL_EPENA IN USBx.INEP[i].DIEPCTL THEN
        IF i = 0 THEN (*control endpoint*) USBx.INEP[i].DIEPCTL := {DIEPCTL_SNAK}
        ELSE USBx.INEP[i].DIEPCTL := {DIEPCTL_EPDIS, DIEPCTL_SNAK}
        END
      ELSE USBx.INEP[i].DIEPCTL := {}
      END;
      USBx.INEP[i].DIEPTSIZ := {}; USBx.INEP[i].DIEPINT := {0..5, 7..10, 12..15}
    END;
    FOR i := 0 TO cfg.dev_endpoints - 1 DO
      IF DOEPCTL_EPENA IN USBx.OUTEP[i].DOEPCTL THEN
        IF i = 0 THEN (*control endpoint*) USBx.OUTEP[i].DOEPCTL := {DOEPCTL_SNAK}
        ELSE USBx.OUTEP[i].DOEPCTL := {DOEPCTL_EPDIS, DOEPCTL_SNAK}
        END
      ELSE USBx.OUTEP[i].DOEPCTL := {}
      END;
      USBx.OUTEP[i].DOEPTSIZ := {}; USBx.OUTEP[i].DOEPINT := {0..5, 7..10, 12..15}
    END;
    EXCL(USBx.DIEPMSK, DIEPMSK_TXFURM);
    USBx.GINTSTS := {0..29, 31}; (* Clear any pending interrupts *)
    (* Enable the common interrupts *)
    IF ~cfg.dma_enable THEN INCL(USBx.GINTMSK, GINTMSK_RXFLVLM) END;
    (* Enable interrupts matching to the Device mode ONLY *)
    USBx.GINTMSK := USBx.GINTMSK + {GINTMSK_USBSUSPM, GINTMSK_USBRST,
      GINTMSK_ENUMDNEM, GINTMSK_IEPINT, GINTMSK_OEPINT, GINTMSK_IISOIXFRM,
      GINTMSK_PXFRM_IISOOXFRM, GINTMSK_WUIM};
    IF cfg.Sof_enable THEN INCL(USBx.GINTMSK, GINTMSK_SOFM) END;
    IF cfg.vbus_sensing_enable THEN USBx.GINTMSK := USBx.GINTMSK + {GINTMSK_SRQIM, GINTMSK_OTGINT} END

    RETURN ret
  END DevInit;

  (**
  * @brief  USB_SetDevAddress : Stop the usb device mode
  * @param  USBx  Selected device
  * @param  address  new device address to be assigned
  *          This parameter can be a value from 0 to 255
  * @retval HAL status
  *)
  PROCEDURE SetDevAddress*(USBx: OTGCore; address: BYTE);
  BEGIN USBx.DCFG := USBx.DCFG - DCFG_DAD_Msk + TOSET(LSL(address, DCFG_DAD_Pos))*DCFG_DAD_Msk
  END SetDevAddress;

  (**
  * @brief  USB_DevConnect : Connect the USB device by enabling Rpu
  * @param  USBx  Selected device
  * @retval HAL status
  *)
  PROCEDURE DevConnect*(USBx: OTGCore);
    VAR reg: SET;
  BEGIN (* In case phy is stopped, ensure to ungate and restore the phy CLK *)
    SYSTEM.GET(ORD(USBx) + PCGCCTL_BASE, reg);
    SYSTEM.PUT(ORD(USBx) + PCGCCTL_BASE, reg-{PCGCCTL_STOPCLK, PCGCCTL_GATECLK});
    EXCL(USBx.DCTL, DCTL_SDIS)
  END DevConnect;

  (**
  * @brief  SetXFSIZ : Initializes the USB OTG GRXFSIZ, DIEPTXF0_HNPTXFSIZ and HPTXFSIZ registers
  * @param  USBx  Selected device
  *)
  PROCEDURE SetXFSIZ*(USBx: OTGCore);
  BEGIN
    IF ORD(USBx) = HS_PERIPH_BASE THEN
      (* set Rx FIFO size *)
      USBx.GRXFSIZ := 200H;
      USBx.DIEPTXF0_HNPTXFSIZ := LSL(100H, 16) + 200H;
      USBx.HPTXFSIZ := LSL(0E0H, 16) + 300H;
    ELSE
      (* set Rx FIFO size *)
      USBx.GRXFSIZ := 80H;
      USBx.DIEPTXF0_HNPTXFSIZ := LSL(60H, 16) + 80H;
      USBx.HPTXFSIZ := LSL(40H, 16) + 0E0H;
    END;
  END SetXFSIZ;

  (**
  * @brief  USB_HostInit : Initializes the USB OTG controller registers
  *         for Host mode
  * @param  USBx  Selected device
  * @param  cfg   pointer to a USB_OTG_CfgTypeDef structure that contains
  *         the configuration information for the specified USBx peripheral.
  * @retval HAL status
  *)
  PROCEDURE HostInit*(USBx: OTGCore; cfg: CfgDesc): BYTE;
    VAR ret: BYTE; i: INTEGER; USBx_HOST!: OTGHostMode; USBx_HCi!: OTGHostChannel;
  BEGIN USBx_HOST := SYSTEM.VAL(OTGHostMode, ORD(USBx) + HOST_BASE); ret := HAL_OK;
    SYSTEM.PUT(ORD(USBx) + PCGCCTL_BASE, {}); (* Restart the Phy Clock *)
    (*
    * Disable HW VBUS sensing. VBUS is internally considered to be always
    * at VBUS-Valid level (5V).
    *)
    INCL(USBx.GCCFG, GCCFG_NOVBUSSENS);
    EXCL(USBx.GCCFG, GCCFG_VBUSBSEN);
    EXCL(USBx.GCCFG, GCCFG_VBUSASEN);
    IF ~(GUSBCFG_PHYSEL IN USBx.GUSBCFG) THEN
      IF cfg.speed = USBH_FSLS_SPEED THEN INCL(USBx_HOST.HCFG, HCFG_FSLSS) (* Force Device Enumeration to FS/LS mode only *)
      ELSE EXCL(USBx_HOST.HCFG, HCFG_FSLSS) (* Set default Max speed support *)
      END
    ELSE EXCL(USBx_HOST.HCFG, HCFG_FSLSS) (* Set default Max speed support *)
    END;
    (* Make sure the FIFOs are flushed. *)
    IF FlushTxFifo(USBx, ALL_FIFOS) # HAL_OK THEN ret := HAL_ERROR END;
    IF FlushRxFifo(USBx) # HAL_OK THEN ret := HAL_ERROR END;
    (* Clear all pending HC Interrupts *) ASSERT(cfg.Host_channels <= 12);
    FOR i := 0 TO cfg.Host_channels - 1 DO
      USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + i*HOST_CHANNEL_SIZE);
      USBx_HCi.HCINT := CLEAR_INTERRUPT_MASK;
      USBx_HCi.HCINTMSK := {}
    END;
    USBx.GINTSTS := CLEAR_INTERRUPT_MASK; (* Clear any pending interrupts *)
    IF ~cfg.dma_enable THEN INCL(USBx.GINTMSK, GINTMSK_RXFLVLM) END; (* Enable the common interrupts *)
    (* Enable interrupts matching to the Host mode ONLY *)
    USBx.GINTMSK :=  USBx.GINTMSK + {GINTMSK_PRTIM, GINTMSK_HCIM, GINTMSK_SOFM,
      GINTSTS_DISCINT, GINTMSK_PXFRM_IISOOXFRM, GINTMSK_WUIM}

    RETURN ret
  END HostInit;

  (**
  * @brief  Return Host Port speed
  * @param  USBx  Selected device
  * @retval speed : Host port device speed
  *          This parameter can be one of these values:
  *            @arg HCD_DEVICE_SPEED_HIGH: High speed mode
  *            @arg HCD_DEVICE_SPEED_FULL: Full speed mode
  *            @arg HCD_DEVICE_SPEED_LOW: Low speed mode
  *)
  PROCEDURE GetHostSpeed*(USBx: OTGCore): SET;
    VAR hprt0: SET;
  BEGIN SYSTEM.GET(ORD(USBx) + HOST_PORT_BASE, hprt0);

    RETURN hprt0*HPRT_PSPD_Msk
  END GetHostSpeed;

  (**
  * @brief  Return Host Current Frame number
  * @param  USBx  Selected device
  * @retval current frame number
  *)
  PROCEDURE GetCurrentFrame*(USBx: OTGCore): INTEGER;
    VAR USBx_HOST!: OTGHostMode;
  BEGIN USBx_HOST := SYSTEM.VAL(OTGHostMode, ORD(USBx) + HOST_BASE);

    RETURN USBx_HOST.HFNUM MOD 10000H
  END GetCurrentFrame;

  (**
  * @brief  Initialize a host channel
  * @param  USBx  Selected device
  * @param  ch_num  Channel number
  *         This parameter can be a value from 1 to 15
  * @param  epnum  Endpoint number
  *          This parameter can be a value from 1 to 15
  * @param  dev_address  Current device address
  *          This parameter can be a value from 0 to 255
  * @param  speed  Current device speed
  *          This parameter can be one of these values:
  *            @arg USB_OTG_SPEED_HIGH: High speed mode
  *            @arg USB_OTG_SPEED_FULL: Full speed mode
  *            @arg USB_OTG_SPEED_LOW: Low speed mode
  * @param  ep_type  Endpoint Type
  *          This parameter can be one of these values:
  *            @arg EP_TYPE_CTRL: Control type
  *            @arg EP_TYPE_ISOC: Isochronous type
  *            @arg EP_TYPE_BULK: Bulk type
  *            @arg EP_TYPE_INTR: Interrupt type
  * @param  mps  Max Packet Size
  *          This parameter can be a value from 0 to 32K
  * @retval HAL state
  *)
  PROCEDURE HC_Init*(USBx: OTGCore; ch_num, epnum, dev_address, speed, ep_type: BYTE; mps: HALFWORD): BYTE;
    VAR ret: BYTE; USBx_HOST!: OTGHostMode; USBx_HCi!: OTGHostChannel;
      HCcharEpDir, HostCoreSpeed, HCcharLowSpeed: SET;
  BEGIN USBx_HOST := SYSTEM.VAL(OTGHostMode, ORD(USBx) + HOST_BASE);  ret := HAL_OK;
    USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + ch_num*HOST_CHANNEL_SIZE);
    USBx_HCi.HCINT := CLEAR_INTERRUPT_MASK; (* Clear old interrupt conditions for this host channel. *)
    (* Enable channel interrupts required for this transfer. *)
    IF ep_type IN {Def.EP_TYPE_CTRL, Def.EP_TYPE_BULK} THEN
      USBx_HCi.HCINTMSK := {HCINTMSK_XFRCM, HCINTMSK_STALLM, HCINTMSK_TXERRM,
        HCINTMSK_DTERRM, HCINTMSK_AHBERR, HCINTMSK_NAKM};
      IF 7 IN TOSET(epnum) THEN INCL(USBx_HCi.HCINTMSK, HCINTMSK_BBERRM)
      ELSIF ORD(USBx) = HS_PERIPH_BASE THEN
        USBx_HCi.HCINTMSK := USBx_HCi.HCINTMSK + {HCINTMSK_NYET, HCINTMSK_ACKM}
      END
    ELSIF ep_type = Def.EP_TYPE_INTR THEN
      USBx_HCi.HCINTMSK := {HCINTMSK_XFRCM, HCINTMSK_STALLM, HCINTMSK_TXERRM,
        HCINTMSK_DTERRM, HCINTMSK_NAKM, HCINTMSK_AHBERR, HCINTMSK_FRMORM};
        IF 7 IN TOSET(epnum) THEN INCL(USBx_HCi.HCINTMSK, HCINTMSK_BBERRM) END
    ELSIF ep_type = Def.EP_TYPE_ISOC THEN
      USBx_HCi.HCINTMSK := {HCINTMSK_XFRCM, HCINTMSK_ACKM, HCINTMSK_AHBERR,
        HCINTMSK_FRMORM};
      IF 7 IN TOSET(epnum) THEN
        USBx_HCi.HCINTMSK := USBx_HCi.HCINTMSK + {HCINTMSK_TXERRM, HCINTMSK_BBERRM}
      END
    ELSE ret := HAL_ERROR
    END;
    USBx_HCi.HCSPLT := {};  (* Clear Hub Start Split transaction *)
    INCL(USBx_HCi.HCINTMSK, HCINTMSK_CHHM); (* Enable host channel Halt interrupt *)
    INCL(USBx_HOST.HAINTMSK, ch_num MOD 10H); (* Enable the top level host channel interrupt. *)
    INCL(USBx.GINTMSK, GINTMSK_HCIM); (* Make sure host channel interrupts are enabled. *)
    (* Program the HCCHAR register *)
    IF 7 IN TOSET(epnum) THEN HCcharEpDir := HCCHAR_EPDIR_Msk ELSE HCcharEpDir := {} END;
    HostCoreSpeed := GetHostSpeed(USBx);
    IF (speed = ORD(LSR(HPRT_LOW_SPEED, HPRT_PSPD_Pos))) & (HostCoreSpeed # HPRT_LOW_SPEED) THEN
      HCcharLowSpeed := {HCCHAR_LSDEV} (* LS device plugged to HUB *)
    ELSE HCcharLowSpeed := {}
    END;
    USBx_HCi.HCCHAR := TOSET(LSL(dev_address, 22))*HCCHAR_DAD_Msk +
      TOSET(LSL(epnum, 11))* HCCHAR_EPNUM_Msk +
      TOSET(LSL(ep_type, 18))*HCCHAR_EPTYP_Msk +
      TOSET(mps)*HCCHAR_MPSIZ_Msk +
      LSL(TOSET(1), HCCHAR_MC_Pos) + HCcharEpDir + HCcharLowSpeed;
    IF ep_type IN {Def.EP_TYPE_INTR, Def.EP_TYPE_ISOC} THEN INCL(USBx_HCi.HCCHAR, HCCHAR_ODDFRM) END

    RETURN ret
  END HC_Init;

  (**
  * @brief  Initiate Do Ping protocol
  * @param  USBx  Selected device
  * @param  hc_num  Host Channel number
  *         This parameter can be a value from 1 to 15
  * @retval HAL state
  *)
  PROCEDURE DoPing*(USBx: OTGCore; ch_num: BYTE);
    VAR USBx_HCi!: OTGHostChannel;
  BEGIN
    USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + ch_num*HOST_CHANNEL_SIZE);
    USBx_HCi.HCTSIZ := LSL(TOSET(1), HCTSIZ_PKTCNT_Pos)*HCTSIZ_PKTCNT_Msk + {HCTSIZ_DOPING};
    (* Set host channel enable *)
    USBx_HCi.HCCHAR := USBx_HCi.HCCHAR - {HCCHAR_CHDIS} + {HCCHAR_CHENA};
  END DoPing;

  (**
  * @brief  Start a transfer over a host channel
  * @param  USBx  Selected device
  * @param  hc  pointer to host channel structure
  * @param  dma USB dma enabled or disabled
  *          This parameter can be one of these values:
  *           0 : DMA feature not used
  *           1 : DMA feature used
  * @retval HAL state
  *)
  PROCEDURE HC_StartXfer*(USBx: OTGCore; VAR hc: HCDesc; dma: BOOLEAN);
    VAR USBx_HOST!: OTGHostMode; USBx_HCi!: OTGHostChannel; ch_num: INTEGER;
      cont: BOOLEAN; num_packets: HALFWORD; tmpreg: SET; len_words: HALFWORD;
  BEGIN ch_num := hc.ch_num; cont := TRUE;
    USBx_HOST := SYSTEM.VAL(OTGHostMode, ORD(USBx) + HOST_BASE);
    USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + ch_num*HOST_CHANNEL_SIZE);
    IF ORD(USBx) = HS_PERIPH_BASE THEN
      (* in DMA mode host Core automatically issues ping in case of NYET/NAK *)
      IF dma THEN
        IF (hc.ep_type = Def.EP_TYPE_CTRL) OR (hc.ep_type = Def.EP_TYPE_BULK) & ~hc.do_ssplit THEN
          USBx_HCi.HCINTMSK := USBx_HCi.HCINTMSK - {HCINTMSK_NYET, HCINTMSK_ACKM, HCINTMSK_NAKM}
        END
      ELSIF (hc.speed = USBH_HS_SPEED) & hc.do_ping THEN DoPing(USBx, hc.ch_num);
        cont := FALSE
      END
    END;
    IF cont THEN
      IF hc.do_ssplit THEN
        num_packets := 1; (* Set number of packet to 1 for Split transaction *)
        IF hc.ep_is_in THEN hc.XferSize := num_packets * hc.max_packet
        ELSE
          IF hc.ep_type = Def.EP_TYPE_ISOC THEN
            IF hc.xfer_len > ISO_SPLT_MPS THEN
              (* Isochrone Max Packet Size for Split mode *)
              hc.XferSize := hc.max_packet; hc.xfer_len := hc.XferSize;
              IF hc.iso_splt_xactPos IN {HCSPLT_BEGIN, HCSPLT_MIDDLE} THEN hc.iso_splt_xactPos := HCSPLT_MIDDLE
              ELSE hc.iso_splt_xactPos := HCSPLT_BEGIN
              END
            ELSE hc.XferSize := hc.xfer_len;
              IF ~(hc.iso_splt_xactPos IN {HCSPLT_BEGIN, HCSPLT_MIDDLE}) THEN hc.iso_splt_xactPos := HCSPLT_FULL
              ELSE hc.iso_splt_xactPos := HCSPLT_END
              END
            END
          ELSIF dma  & (hc.xfer_len > hc.max_packet) THEN hc.XferSize := num_packets * hc.max_packet
          ELSE hc.XferSize := hc.xfer_len
          END
        END
      ELSE (* Compute the expected number of packets associated to the transfer *)
        IF hc.xfer_len > 0 THEN num_packets := (hc.xfer_len + hc.max_packet - 1) DIV hc.max_packet;
          IF num_packets > HC_MAX_PKT_CNT THEN num_packets := HC_MAX_PKT_CNT;
            hc.XferSize := num_packets * hc.max_packet
          END
        ELSE num_packets := 1
        END;
        (*
        * For IN channel HCTSIZ.XferSize is expected to be an integer multiple of
        * max_packet size.
        *)
        IF hc.ep_is_in THEN hc.XferSize := num_packets * hc.max_packet ELSE hc.XferSize := hc.xfer_len END
      END;
      (* Initialize the HCTSIZn register *)
      USBx_HCi.HCTSIZ := TOSET(hc.XferSize)*HCTSIZ_XFRSIZ_Msk +
        LSL(TOSET(num_packets), HCTSIZ_PKTCNT_Pos)*HCTSIZ_PKTCNT_Msk +
        LSL(TOSET(hc.data_pid), HCTSIZ_DPID_Pos)*HCTSIZ_DPID_Msk;
      IF dma THEN USBx_HCi.HCDMA := hc.xfer_buff (* xfer_buff MUST be 32-bits aligned *) END;
      (*if frame count is even, the next frame is odd*)
      USBx_HCi.HCCHAR := USBx_HCi.HCCHAR - HCCHAR_ODDFRM_Msk +
        LSL(TOSET(ORD(~ODD(USBx_HOST.HFNUM))), HCCHAR_ODDFRM);
      IF hc.do_ssplit THEN
        (* Set Hub start Split transaction *)
        USBx_HCi.HCSPLT := LSL(TOSET(hc.hub_addr), HCSPLT_HUBADDR_Pos) +
          TOSET(hc.hub_port_nbr) + {HCSPLT_SPLITEN};
        (* unmask ack & nyet for IN/OUT transactions *)
        USBx_HCi.HCINTMSK := USBx_HCi.HCINTMSK + {HCINTMSK_ACKM, HCINTMSK_NYET};
        IF hc.do_csplit & ~hc.ep_is_in THEN
          INCL(USBx_HCi.HCSPLT, HCSPLT_COMPLSPLT);
          INCL(USBx_HCi.HCINTMSK, HCINTMSK_NYET)
        END;
        IF (hc.ep_type IN {Def.EP_TYPE_ISOC, Def.EP_TYPE_INTR}) & hc.do_csplit & hc.ep_is_in THEN
          INCL(USBx_HCi.HCSPLT, HCSPLT_COMPLSPLT)
        END;
        (* Position management for iso out transaction on split mode *)
        IF (hc.ep_type = Def.EP_TYPE_ISOC) & ~hc.ep_is_in THEN
          (* Set data payload position *)
          IF hc.iso_splt_xactPos = HCSPLT_BEGIN THEN (* First data payload for OUT Transaction *)
            USBx_HCi.HCSPLT := USBx_HCi.HCSPLT + HCSPLT_XACTPOS_BEGIN
          ELSIF hc.iso_splt_xactPos = HCSPLT_MIDDLE THEN (* Middle data payload for OUT Transaction *)
            USBx_HCi.HCSPLT := USBx_HCi.HCSPLT + HCSPLT_XACTPOS_MID
          ELSIF hc.iso_splt_xactPos = HCSPLT_END THEN (* End data payload for OUT Transaction *)
            USBx_HCi.HCSPLT := USBx_HCi.HCSPLT + HCSPLT_XACTPOS_END
          ELSIF hc.iso_splt_xactPos = HCSPLT_FULL THEN (* Entire data payload for OUT Transaction *)
            USBx_HCi.HCSPLT := USBx_HCi.HCSPLT + HCSPLT_XACTPOS_ALL
          END
        END
      ELSE USBx_HCi.HCSPLT := {} (* Clear Hub Start Split transaction *)
      END;
      tmpreg := USBx_HCi.HCCHAR - {HCCHAR_CHDIS}; (* Set host channel enable *)
      (* make sure to set the correct ep direction *)
      IF hc.ep_is_in THEN INCL(tmpreg, HCCHAR_EPDIR) ELSE EXCL(tmpreg, HCCHAR_EPDIR) END;
      INCL(tmpreg, HCCHAR_CHENA);
      USBx_HCi.HCCHAR := tmpreg;
      IF dma THEN (* dma mode *) cont := FALSE END
    END;
    IF cont THEN
      IF ~hc.ep_is_in & (hc.xfer_len > 0) & ~hc.do_csplit THEN
        IF hc.ep_type IN {Def.EP_TYPE_CTRL, Def.EP_TYPE_BULK} THEN (* Non periodic transfer *)
          len_words := (hc.xfer_len + 3) DIV 4;
          (* check if there is enough space in FIFO space *)
          IF len_words > ORD(USBx.HNPTXSTS*HNPTXSTS_NPTXFSAV_Msk) THEN
            INCL(USBx.GINTMSK, GINTMSK_NPTXFEM); (* need to process data in nptxfempty interrupt *)
          END
        ELSIF hc.ep_type IN {Def.EP_TYPE_INTR, Def.EP_TYPE_ISOC} THEN (* Periodic transfer *)
          len_words := (hc.xfer_len + 3) DIV 4;
          (* check if there is enough space in FIFO space *)
          IF len_words > ORD(USBx_HOST.HPTXSTS*HPTXSTS_PTXFSAVL_Msk) THEN (* split the transfer *)
            INCL(USBx.GINTMSK, GINTMSK_PTXFEM) (* need to process data in ptxfempty interrupt *)
          END
        END;
        WritePacket(USBx, hc.xfer_buff, hc.ch_num, hc.xfer_len, FALSE) (* Write packet into the Tx FIFO. *)
      END
    END
  END HC_StartXfer;

  (**
  * @brief  USB_DevDisconnect : Disconnect the USB device by disabling Rpu
  * @param  USBx  Selected device
  * @retval HAL status
  *)
  PROCEDURE DevDisconnect*(USBx: OTGCore);
    VAR reg: SET;
  BEGIN (* In case phy is stopped, ensure to ungate and restore the phy CLK *)
    SYSTEM.GET(ORD(USBx) + PCGCCTL_BASE, reg);
    SYSTEM.PUT(ORD(USBx) + PCGCCTL_BASE, reg - {PCGCCTL_STOPCLK, PCGCCTL_GATECLK});
    INCL(USBx.DCTL, DCTL_SDIS)
  END DevDisconnect;

  (**
  * @brief  USB_ReadInterrupts: return the global USB interrupt status
  * @param  USBx  Selected device
  * @retval USB Global Interrupt status
  *)
  PROCEDURE ReadInterrupts*(USBx: OTGCore): SET;
    RETURN USBx.GINTSTS*USBx.GINTMSK
  END ReadInterrupts;

  (**
  * @brief  USB_ReadChInterrupts: return USB channel interrupt status
  * @param  USBx  Selected device
  * @param  chnum Channel number
  * @retval USB Channel Interrupt status
  *)
  PROCEDURE ReadChInterrupts*(USBx: OTGCore; chnum:BYTE): SET;
    VAR USBx_HCi!: OTGHostChannel;
  BEGIN USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + chnum*HOST_CHANNEL_SIZE);

    RETURN USBx_HCi.HCINT*USBx_HCi.HCINTMSK
  END ReadChInterrupts;

  (**
  * @brief  USB_ReadDevAllOutEpInterrupts: return the USB device OUT endpoints interrupt status
  * @param  USBx  Selected device
  * @retval USB Device OUT EP interrupt status
  *)
  PROCEDURE ReadDevAllOutEpInterrupts*(USBx: OTGCore): SET;
  BEGIN
    RETURN LSR(USBx.DAINT*USBx.DAINTMSK*DAINT_OEPINT_Msk, DAINT_OEPINT_Pos)
  END ReadDevAllOutEpInterrupts;

  (**
  * @brief  USB_ReadDevAllInEpInterrupts: return the USB device IN endpoints interrupt status
  * @param  USBx  Selected device
  * @retval USB Device IN EP interrupt status
  *)
  PROCEDURE ReadDevAllInEpInterrupts*(USBx: OTGCore): SET;
  BEGIN
    RETURN LSR(USBx.DAINT*USBx.DAINTMSK*DAINT_IEPINT_Msk, DAINT_IEPINT_Pos)
  END ReadDevAllInEpInterrupts;

  (**
  * @brief  Returns Device OUT EP non masked Interrupts
  * @param  USBx  Selected device
  * @param  epnum  endpoint number
  *          This parameter can be a value from 0 to 15
  * @retval Device OUT EP Interrupt register
  *)
  PROCEDURE ReadDevOutEPInterrupts*(USBx: OTGCore; epnum: BYTE): SET;
    RETURN USBx.OUTEP[epnum].DOEPINT*USBx.DOEPMSK
  END ReadDevOutEPInterrupts;

(**
  * @brief  Returns Device IN EP non masked Interrupts
  * @param  USBx  Selected device
  * @param  epnum  endpoint number
  *          This parameter can be a value from 0 to 15
  * @retval Device IN EP Interrupt register
  *)
  PROCEDURE ReadDevInEPInterrupts*(USBx: OTGCore; epnum: BYTE): SET;
    RETURN USBx.INEP[epnum].DIEPINT*(USBx.DIEPMSK + LSL(LSR(USBx.DIEPEMPMSK, epnum MOD 10H)*{0}, DIEPINT_TXFE))
  END ReadDevInEPInterrupts;

  (**
  * @brief  Clears Device OUT EP Interrupts
  * @param  USBx  Selected device
  * @param  epnum  endpoint number
  *          This parameter can be a value from 0 to 15
  * @param  flags  interrupts to clear
  *)
  PROCEDURE ClearOutEPInterrupts*(USBx: OTGCore; epnum: BYTE; flags: SET);
  BEGIN USBx.OUTEP[epnum].DOEPINT := flags
  END ClearOutEPInterrupts;

  (**
  * @brief  Clears Device IN EP Interrupts
  * @param  USBx  Selected device
  * @param  epnum  endpoint number
  *          This parameter can be a value from 0 to 15
  * @param  flags  interrupts to clear
  *)
  PROCEDURE ClearInEPInterrupts*(USBx: OTGCore; epnum: BYTE; flags: SET);
  BEGIN USBx.INEP[epnum].DIEPINT := flags
  END ClearInEPInterrupts;

  (**
  * @brief Read all host channel interrupts status
  * @param  USBx  Selected device
  * @retval HAL state
  *)
  PROCEDURE HC_ReadInterrupt*(USBx: OTGCore): SET;
    VAR USBx_HOST!: OTGHostMode;
  BEGIN USBx_HOST := SYSTEM.VAL(OTGHostMode, ORD(USBx) + HOST_BASE);

    RETURN USBx_HOST.HAINT*{0..15}
  END HC_ReadInterrupt;

  (**
  * @brief  Activate EP0 for Setup transactions
  * @param  USBx  Selected device
  * @retval HAL status
  *)
  PROCEDURE ActivateSetup*(USBx: OTGCore);
  BEGIN USBx.INEP[0].DIEPCTL := USBx.INEP[0].DIEPCTL - DIEPCTL_MPSIZ_Msk; (* Set the MPS of the IN EP0 to 64 bytes *)
    INCL(USBx.DCTL, DCTL_CGINAK)
  END ActivateSetup;

  (**
  * @brief  USB_InitFSLSPClkSel : Initializes the FSLSPClkSel field of the
  *         HCFG register on the PHY type and set the right frame interval
  * @param  USBx  Selected device
  * @param  freq  clock frequency
  *          This parameter can be one of these values:
  *           HCFG_48_MHZ : Full Speed 48 MHz Clock
  *           HCFG_6_MHZ : Low Speed 6 MHz Clock
  * @retval HAL status
  *)
  PROCEDURE InitFSLSPClkSel*(USBx: OTGCore; freq: SET): BYTE;
    VAR res: BYTE; USBx_HOST!: OTGHostMode;
  BEGIN USBx_HOST := SYSTEM.VAL(OTGHostMode, ORD(USBx) + HOST_BASE);
    USBx_HOST.HCFG := USBx_HOST.HCFG - HCFG_FSLSPCS_Msk + freq*HCFG_FSLSPCS_Msk;
    res := HAL_OK;
    IF freq = HCFG_48_MHZ THEN USBx_HOST.HFIR := HFIR_48_MHZ
    ELSIF freq = HCFG_6_MHZ THEN USBx_HOST.HFIR := HFIR_6_MHZ
    ELSE res := HAL_ERROR
    END;

    RETURN res
  END InitFSLSPClkSel;

  (**
  * @brief  Halt a host channel
  * @param  USBx  Selected device
  * @param  hc_num  Host Channel number
  *         This parameter can be a value from 1 to 15
  * @retval HAL state
  *)
  PROCEDURE HC_Halt*(USBx: OTGCore; hc_num: BYTE);
    VAR USBx_HCi!: OTGHostChannel; HcEpType: SET; USBx_HOST!: OTGHostMode;
    PROCEDURE disableChannel(USBx: OTGCore; USBx_HCi: OTGHostChannel);
      VAR count: INTEGER;
    BEGIN count := 0;
      IF USBx.HNPTXSTS*HNPTXSTS_NPTQXSAV_Msk = {} THEN
        EXCL(USBx_HCi.HCCHAR, HCCHAR_CHENA); INCL(USBx_HCi.HCCHAR, HCCHAR_CHENA);
        REPEAT INC(count)
        UNTIL (count > 1000) OR ~(HCCHAR_CHENA IN USBx_HCi.HCCHAR)
      ELSE INCL(USBx_HCi.HCCHAR, HCCHAR_CHENA)
      END
    END disableChannel;
  BEGIN USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + hc_num*HOST_CHANNEL_SIZE);
    (* In buffer DMA, Channel disable must not be programmed for non-split periodic channels.
     At the end of the next uframe/frame (in the worst case), the core generates a channel halted
     and disables the channel automatically. *)
    HcEpType := USBx_HCi.HCCHAR*HCCHAR_EPTYP_Msk;
    IF  ~(GAHBCFG_DMAEN IN USBx.GAHBCFG) OR (HCSPLT_SPLITEN IN USBx_HCi.HCSPLT) OR
      (HCCHAR_CHENA IN USBx_HCi.HCCHAR) & (HcEpType # HCCHAR_ISOC) & (HcEpType # HCCHAR_INTR) THEN
      (* Check for space in the request queue to issue the halt. *)
      IF (HcEpType = HCCHAR_CTRL) OR (HcEpType = HCCHAR_BULK) THEN
        INCL(USBx_HCi.HCCHAR, HCCHAR_CHDIS);
        IF ~(GAHBCFG_DMAEN IN USBx.GAHBCFG) THEN disableChannel(USBx, USBx_HCi)
        ELSE INCL(USBx_HCi.HCCHAR, HCCHAR_CHENA)
        END
      ELSE INCL(USBx_HCi.HCCHAR, HCCHAR_CHDIS); disableChannel(USBx, USBx_HCi)
      END
    END
  END HC_Halt;

  (**
  * @brief  USB_OTG_ResetPort : Reset Host Port
  * @param  USBx  Selected device
  * @retval HAL status
  * @note (1)The application must wait at least 10 ms
  *   before clearing the reset bit.
  *)
  PROCEDURE ResetPort*(USBx: OTGCore);
    VAR hprt0: SET;
  BEGIN SYSTEM.GET(ORD(USBx) + HOST_PORT_BASE, hprt0);
    hprt0 := hprt0 - {HPRT_PENA, HPRT_PCDET, HPRT_PENCHNG, HPRT_POCCHNG};
    SYSTEM.PUT(ORD(USBx) + HOST_PORT_BASE,hprt0 +  {HPRT_PRST});
    Kernel.Delayms(100); (* See Note #1 *)
    SYSTEM.PUT(ORD(USBx) + HOST_PORT_BASE, hprt0 - {HPRT_PRST});
    Kernel.Delayms(10)
  END ResetPort;

  (**
  * @brief  USB_DriveVbus : activate or de-activate vbus
  * @param  state  VBUS state
  *          This parameter can be one of these values:
  *           0 : Deactivate VBUS
  *           1 : Activate VBUS
  * @retval HAL status
  *)
  PROCEDURE DriveVbus*(USBx: OTGCore; state: BOOLEAN);
    VAR hprt0: SET;
  BEGIN SYSTEM.GET(ORD(USBx) + HOST_PORT_BASE, hprt0);
    hprt0 := hprt0 - (HPRT_PENA_Msk + HPRT_PCDET_Msk + HPRT_PENCHNG_Msk + HPRT_POCCHNG_Msk);
    IF ~(HPRT_PPWR IN hprt0) & state THEN SYSTEM.PUT(ORD(USBx) + HOST_PORT_BASE, hprt0 + HPRT_PPWR_Msk) END;
    IF (HPRT_PPWR IN hprt0) & ~state THEN SYSTEM.PUT(ORD(USBx) + HOST_PORT_BASE, hprt0 - HPRT_PPWR_Msk) END
  END DriveVbus;

  (**
  * @brief  Stop Host Core
  * @param  USBx  Selected device
  * @retval HAL state
  *)
  PROCEDURE StopHost*(USBx: OTGCore): BYTE;
    VAR ret: BYTE; count, i: INTEGER; USBx_HOST!: OTGHostMode; USBx_HCi!: OTGHostChannel;
  BEGIN (*DisableGlobalInt(USBx);
    RETURN CoreReset(USBx)*)
    ret := HAL_OK; count := 0; USBx_HOST := SYSTEM.VAL(OTGHostMode, ORD(USBx) + HOST_BASE);
    DisableGlobalInt(USBx);
    (* Flush USB FIFO *)
    IF (FlushTxFifo(USBx, ALL_FIFOS) # HAL_OK) OR
      (FlushRxFifo(USBx) # HAL_OK) THEN ret := HAL_ERROR
    ELSE
      (* Flush out any leftover queued requests. *)
      FOR i := 0 TO 15 DO
        USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + i*HOST_CHANNEL_SIZE);
        USBx_HCi.HCCHAR := USBx_HCi.HCCHAR + {HCCHAR_CHDIS} - {HCCHAR_CHENA, HCCHAR_EPDIR}
      END;
      (* Halt all channels to put them into a known state. *)
      FOR i := 0 TO 15 DO
        USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + i*HOST_CHANNEL_SIZE);
        USBx_HCi.HCCHAR := USBx_HCi.HCCHAR + {HCCHAR_CHDIS, HCCHAR_CHENA} - {HCCHAR_EPDIR};
        REPEAT INC(count) UNTIL (count > 1000) OR ~(HCCHAR_CHENA IN USBx_HCi.HCCHAR)
      END;
      (* Clear any pending Host interrupts *)
      USBx_HOST.HAINT := CLEAR_INTERRUPT_MASK; USBx.GINTSTS := CLEAR_INTERRUPT_MASK;
    END;
    EnableGlobalInt(USBx);

    RETURN ret
  END StopHost;

END LLUSB.
