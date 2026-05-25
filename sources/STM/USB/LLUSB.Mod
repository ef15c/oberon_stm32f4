MODULE LLUSB;
  (** ported to Oberon from:
  ******************************************************************************
  * @file    stm32f4xx_ll_usb
  * @author  MCD Application Team
  * @brief   HCD HAL module.
  ******************************************************************************
  *)
  IMPORT SYSTEM, Kernel, Log := USBLog, Def := USBHDef;

  CONST
  (*!< USB registers base address *)
    HS_PERIPH_BASE* = 40040000H;
    FS_PERIPH_BASE* = 50000000H;

    GLOBAL_BASE* = 0;
    DEVICE_BASE* = 800H;
    IN_ENDPOINT_BASE* = 900H;
    OUT_ENDPOINT_BASE* = 0B00H;
    EP_REG_SIZE* = 20H;
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
(* URB_IDLE* = 0; *)
    URB_DONE* = 1;
    URB_NOTREADY* = 2;
    URB_NYET* = 3;
    URB_ERROR* = 4;
    URB_STALL* = 5;

 (**
  * @brief  Host channel States  definition
  *)
(* HC_IDLE* = 0; *)
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
    USB_CURRENT_MODE_MAX_DELAY_MS* = 200;

  (**
  * @brief  USB Mode definition
  *)

    USB_DEVICE_MODE* = 0;
    USB_HOST_MODE* = 1;
    USB_DRD_MODE* = 2;

  (** @defgroup USB_LL_HFIR_Defines USB Low Layer frame interval Defines
  * @{
  *)
    HFIR_6_MHZ* = 6000;
    HFIR_60_MHZ* = 60000;
    HFIR_48_MHZ* = 48000;

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

  (********************  Bit definition for USB_OTG_GUSBCFG register  ********************)
    GUSBCFG_TOCAL_Msk* = {0..2}; (*!< FS timeout calibration *)
    GUSBCFG_PHYSEL* = 6; (*!< USB 2.0 high-speed ULPI PHY or USB 1.1 full-speed serial transceiver select *)
    GUSBCFG_PHYSEL_Msk* = {GUSBCFG_PHYSEL};
    GUSBCFG_SRPCAP* = 8; (*!< SRP-capable *)
    GUSBCFG_SRPCAP_Msk* = {GUSBCFG_SRPCAP};
    GUSBCFG_HNPCAP* = 9; (*!< HNP-capable *)
    GUSBCFG_HNPCAP_Msk* = {GUSBCFG_HNPCAP};
    GUSBCFG_TRDT_Msk* = {10..13}; (*!< USB turnabout time *)
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
    GINTSTS_BOUTNAKEFF* = 7; (*!< Global OUT NAK effective                       *)
    GINTSTS_BOUTNAKEFF_Msk* = {GINTSTS_BOUTNAKEFF};
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

  (********************  Bit definition forUSB_OTG_HCFG register  ********************)

    HCFG_FSLSPCS_Msk* = {0..1}; (*!< FS/LS PHY clock select  *)
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
    HPRT_PSPD_HIGH_SPEED* = {};
    HPRT_PSPD_FULL_SPEED* = {17};
    HPRT_PSPD_LOW_SPEED* = {18};

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
    HCCHAR_MC_Msk* = {20..21}; (*!< Multi Count (MC) / Error Count (EC) *)
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

  (********************  Bit definition for USB_OTG_HNPTXSTS register  ********************)
    HNPTXSTS_NPTXFSAV_Msk* = {0..15}; (*Non-periodic TxFIFO space available*)
    HNPTXSTS_NPTQXSAV_Msk* = {16..23}; (*Non-periodic transmit request queue space available*)
    HNPTXSTS_NPTXQTOP_Msk* = {24..30}; (*Top of the non-periodic transmit request queue*)

  (********************  Bit definition for USB_OTG_HCTSIZ register  ********************)
    HCTSIZ_XFRSIZ_Msk* = {0..18}; (*!< Transfer size *)
    HCTSIZ_PKTCNT_Msk* = {19..28}; (*!< Packet count *)
    HCTSIZ_DPID_Msk* = {29..30}; (*!< Data PID *)
    HCTSIZ_DOPING* = 31; (*!< Do PING *)
    HCTSIZ_DOPING_Msk* = {HCTSIZ_DOPING};

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
    GRXSTSP_EPNUM_Msk* = {0..3}; (*!< Endpoint or channel number  *)
    GRXSTSP_BCNT_Msk* = {4..14}; (*!< byte count of received data *)
    GRXSTSP_DPID_Msk* = {15..16}; (*!< data PID of the received packet*)
    GRXSTSP_PKTSTS_Msk* = {17..20}; (* packet status *)
    GRXSTS_PKTSTS_IN* = {18};
    GRXSTS_PKTSTS_IN_XFER_COMP* = {17..18};
    GRXSTS_PKTSTS_DATA_TOGGLE_ERR* = {17, 19};
    GRXSTS_PKTSTS_HALTED* = {17..19};

  TYPE
  (**
  * @brief USB_OTG_Core_Registers
  *)
    OTGCore* = POINTER TO OTGCoreDesc;
    OTGCoreDesc* = RECORD
      GOTGCTL*,              (*!< USB_OTG Control and Status Register          000h *)
      GOTGINT*,              (*!< USB_OTG Interrupt Register                   004h *)
      GAHBCFG*,             (*!< Core AHB Configuration Register              008h *)
      GUSBCFG*,              (*!< Core USB Configuration Register              00Ch *)
      GRSTCTL*,               (*!< Core Reset Register                          010h *)
      GINTSTS*,               (*!< Core Interrupt Register                      014h *)
      GINTMSK*,              (*!< Core Interrupt Mask Register                 018h *)
      GRXSTSR*,              (*!< Receive Sts Q Read Register                  01Ch *)
      GRXSTSP*: SET;              (*!< Receive Sts Q Read & POP Register            020h *)
      GRXFSIZ*,               (*!< Receive FIFO Size Register                   024h *)
      DIEPTXF0_HNPTXFSIZ*: INTEGER;   (*!< EP0 / Non Periodic Tx FIFO Size Register     028h *)
      HNPTXSTS*: SET;     (*!< Non Periodic Tx FIFO/Queue Sts reg           02Ch *)
      Reserved30: ARRAY 2 OF INTEGER; (*!< Reserved                                     030h *)
      GCCFG*: SET;                 (*!< General Purpose IO Register                  038h *)
      CID*: INTEGER;      (*!< User ID Register                             03Ch *)
      Reserved40: ARRAY 48 OF INTEGER; (*!< Reserved                                0x40-0xFF *)
      HPTXFSIZ*: INTEGER; (*!< Host Periodic Tx FIFO Size Reg               100h *)
      DIEPTXF*: ARRAY 0FH OF INTEGER (*!< dev Periodic Transmit FIFO                        *)
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
      Reserved: ARRAY 2 OF INTEGER;      (*!< Reserved                                      *)
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
    END

    RETURN ret
  END CoreInit;

  (**
  * @brief  Returns USB core mode
  * @param  USBx  Selected device
  * @retval return core mode : Host or Device
  *          This parameter can be one of these values:
  *           1 : Host
  *           0 : Device
  *)
  PROCEDURE GetMode*(USBx: OTGCore): INTEGER;
    RETURN ORD(USBx.GINTSTS*GINTSTS_CMOD_Msk)
  END GetMode;

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
    USBx.GUSBCFG := USBx.GUSBCFG - ({GUSBCFG_FHMOD} + {GUSBCFG_FDMOD});
    IF mode = USB_HOST_MODE THEN INCL(USBx.GUSBCFG, GUSBCFG_FHMOD);
      REPEAT Kernel.Delayms(10); INC(ms, 10)
      UNTIL (GetMode(USBx) = USB_HOST_MODE) OR (ms >= USB_CURRENT_MODE_MAX_DELAY_MS)
    ELSIF mode = USB_DEVICE_MODE THEN INCL(USBx.GUSBCFG, GUSBCFG_FDMOD);
      REPEAT Kernel.Delayms(10); INC(ms, 10)
      UNTIL (GetMode(USBx) = USB_DEVICE_MODE) OR (ms >= USB_CURRENT_MODE_MAX_DELAY_MS)
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
    SYSTEM.PUT(ORD(USBx) + PCGCCTL_BASE, 0); (* Restart the Phy Clock *)
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
    IF FlushTxFifo(USBx, 10H (* all Tx FIFOs *)) # HAL_OK THEN ret := HAL_ERROR END;
    IF FlushRxFifo(USBx) # HAL_OK THEN ret := HAL_ERROR END;
    (* Clear all pending HC Interrupts *) ASSERT(cfg.Host_channels <= 12);
    FOR i := 0 TO cfg.Host_channels - 1 DO
      USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + i*HOST_CHANNEL_SIZE);
      USBx_HCi.HCINT := CLEAR_INTERRUPT_MASK;
      USBx_HCi.HCINTMSK := {}
    END;
    USBx.GINTMSK := {}; (* Disable all interrupts. *)
    USBx.GINTSTS := CLEAR_INTERRUPT_MASK; (* Clear any pending interrupts *)

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
    IF cfg.dma_enable THEN INCL(USBx.GINTMSK, GINTMSK_RXFLVLM) END; (* Enable the common interrupts *)
    (* Enable interrupts matching to the Host mode ONLY *)
    USBx.GINTMSK :=  USBx.GINTMSK + ({GINTMSK_PRTIM} + {GINTMSK_HCIM} + {GINTMSK_SOFM} +
      {GINTSTS_DISCINT} + {GINTMSK_PXFRM_IISOOXFRM} + {GINTMSK_WUIM})

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
      count32b := (len + 3) DIV 4;
      FOR i := 0 TO count32b - 1 DO SYSTEM.GET(src, t);
        SYSTEM.PUT(ORD(USBx) + FIFO_BASE + ch_ep_num*FIFO_SIZE, t);
        INC(src, 4)
      END
    END

  END WritePacket;

  (**
  * @brief  USB_ReadPacket : read a packet from the RX FIFO
  * @param  USBx  Selected device
  * @param  dest  source pointer
  * @param  len  Number of bytes to read
  * @retval pointer to destination buffer
  *)
  PROCEDURE ReadPacket*(USBx: OTGCore; dest, len: INTEGER): INTEGER;
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

    RETURN dest
  END ReadPacket;

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
        USBx_HCi.HCINTMSK := {HCINTMSK_NYET, HCINTMSK_ACKM}
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
    IF (speed = ORD(LSR(HPRT_PSPD_LOW_SPEED, HPRT_PSPD_Pos))) & (HostCoreSpeed # HPRT_PSPD_LOW_SPEED) THEN
      HCcharLowSpeed := {HCCHAR_LSDEV} (* LS device plugged to HUB *)
    ELSE HCcharLowSpeed := {}
    END;
    USBx_HCi.HCCHAR := TOSET(LSL(dev_address, 22))*HCCHAR_DAD_Msk +
      TOSET(LSL(epnum, 11))* HCCHAR_EPNUM_Msk +
      TOSET(LSL(ep_type, 18))*HCCHAR_EPTYP_Msk +
      TOSET(mps)*HCCHAR_MPSIZ_Msk +
      {20} + HCcharEpDir + HCcharLowSpeed;
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
    USBx_HCi.HCTSIZ := LSL(TOSET(1), 19)*HCTSIZ_PKTCNT_Msk + {HCTSIZ_DOPING};
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
        LSL(TOSET(num_packets), 19)*HCTSIZ_PKTCNT_Msk +
        LSL(TOSET(hc.data_pid), 29)*HCTSIZ_DPID_Msk;
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
    VAR USBx_HCi!: OTGHostChannel; HcEpType: SET;
    PROCEDURE disableChannel(USBx: OTGCore; USBx_HCi: OTGHostChannel);
      VAR count: INTEGER;
    BEGIN
      IF USBx.HNPTXSTS*HNPTXSTS_NPTQXSAV_Msk = {} THEN
        EXCL(USBx_HCi.HCCHAR, HCCHAR_CHENA); INCL(USBx_HCi.HCCHAR, HCCHAR_CHENA);
        REPEAT INC(count)
        UNTIL (count > 1000) OR ~(HCCHAR_CHENA IN USBx_HCi.HCCHAR)
      ELSE INCL(USBx_HCi.HCCHAR, HCCHAR_CHENA)
      END
    END disableChannel;
  BEGIN USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + hc_num*HOST_CHANNEL_SIZE);
    Log.Debug("Halt request for channel "); Log.DebugInt(hc_num, 1); Log.DebugLn;
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
    VAR ret: BYTE; i, count: INTEGER; USBx_HOST!: OTGHostMode; USBx_HCi!: OTGHostChannel;
  BEGIN USBx_HOST := SYSTEM.VAL(OTGHostMode, ORD(USBx) + HOST_BASE); ret := HAL_OK; count := 0;
    DisableGlobalInt(USBx);
    (* Flush USB FIFO *)
    IF (FlushTxFifo(USBx, ALL_FIFOS) # HAL_OK ) OR (FlushRxFifo(USBx) # HAL_OK) THEN ret := HAL_ERROR
    ELSE (* Flush out any leftover queued requests. *)
      FOR i := 0 TO 15 DO
        USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + i*HOST_CHANNEL_SIZE);
        USBx_HCi.HCCHAR := USBx_HCi.HCCHAR + {HCCHAR_CHDIS} - {HCCHAR_CHENA, HCCHAR_EPDIR};
      END;
      FOR i := 0 TO 15 DO (* Halt all channels to put them into a known state. *)
        USBx_HCi := SYSTEM.VAL(OTGHostChannel, ORD(USBx) + HOST_CHANNEL_BASE + i*HOST_CHANNEL_SIZE);
        USBx_HCi.HCCHAR := USBx_HCi.HCCHAR + {HCCHAR_CHDIS, HCCHAR_CHENA} - {HCCHAR_EPDIR};
        REPEAT INC(count) UNTIL (count > 1000) OR (HCCHAR_CHENA IN USBx_HCi.HCCHAR)
      END;
      (* Clear any pending Host interrupts *)
      USBx_HOST.HAINT := CLEAR_INTERRUPT_MASK;
      USBx.GINTSTS := CLEAR_INTERRUPT_MASK;
      EnableGlobalInt(USBx)
    END

    RETURN ret
  END StopHost;

END LLUSB.
