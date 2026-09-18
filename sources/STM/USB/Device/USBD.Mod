MODULE USBD;
  (** USB device library, ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   USB host library
  ******************************************************************************
  *)
  IMPORT Log := USBLog, Def := USBDef, DDef := USBDDef, DH := USBDHal;

  VAR processTask: Def.Task;

  PROCEDURE ProcessDevice(dev: Def.Handle);
    (*TODO*)
  END ProcessDevice;
  
  PROCEDURE Process;
    VAR i: BYTE;
  BEGIN
    FOR i := 0 TO Def.NB_OTG_CORES - 1 DO
      IF Def.usbCores[i] # NIL THEN ProcessDevice(Def.usbCores[i]) END
    END
  END Process;

 (**
  * @brief  USBD_Init
  *         Initialize the Device portion of the driver.
  * @param  core: Core Driver Handle
  * @param  id: the Core id
  * @retval device driver handle
  *)
  PROCEDURE Init*(core: Def.Handle; id: BYTE): Def.Handle;
    VAR dev!: DDef.Handle;
  BEGIN dev := DH.Init(core, id);
    IF dev # NIL THEN
(*
#ifdef USE_USBD_COMPOSITE
  /* Parse the table of classes in use */
  for (uint32_t i = 0; i < USBD_MAX_SUPPORTED_CLASS; i++)
  {
    /* Unlink previous class*/
    pdev->pClass[i] = NULL;
    pdev->pUserData[i] = NULL;

    /* Set class as inactive */
    pdev->tclasslist[i].Active = 0;
    pdev->NumClasses = 0;
    pdev->classId = 0;
  }
#else
*)
      (* Unlink previous class*)
      dev.Class[0] := NIL;
      dev.UserData[0] := NIL;
(*
#endif /* USE_USBD_COMPOSITE */
*)
      dev.ConfDesc := NIL;
      (* Assign USBD Descriptors *)
      dev.User(id, Def.USER_ASSIGN_DESCRIPTORS);
      (* Set Device initial State *)
      dev.state := DDef.STATE_DEFAULT;
      IF processTask = NIL THEN (*install USB core process task*)
        processTask := Def.NewTask(Process, 5); Def.Install(processTask)
      END
    END

    RETURN dev
  END Init;

  (**
  * @brief  USBD_Start
  *         Start the USB Device Core.
  * @param  pdev: Device Handle
  * @retval USBD Status
  *)
  PROCEDURE Start*(dev: Def.Handle);
  BEGIN
(*
#ifdef USE_USBD_COMPOSITE
  pdev->classId = 0U;
#endif /* USE_USBD_COMPOSITE */
*)
    CASE dev OF
      DDef.Handle: DH.Start(dev); (* Start the low level driver  *)
        Log.Flush
    | Def.Handle: ASSERT(FALSE)
    END
  END Start;

  PROCEDURE RegisterDescriptors*(dev: Def.Handle; descriptors: Def.DescriptorGetters);
  BEGIN dev(DDef.Handle).Desc := descriptors(DDef.DescriptorGetters)
  END RegisterDescriptors;

  (**
  * @brief  USBD_RegisterClass
  *         Link class driver to Device Core.
  * @param  pdev: Device Handle
  * @param  pclass: Class handle
  * @retval USBD Status
  *)
  PROCEDURE RegisterClass*(dev: Def.Handle; class: Def.Class);
  BEGIN
    CASE dev OF
      DDef.Handle:
        IF class = NIL THEN Log.Error("Invalid Class handle"); Log.ErrorLn
        ELSE dev.Class[0] := class(DDef.Class); (* link the class to the USB Device handle *)
          (* Get Device Configuration Descriptor *)
          IF dev.useUsbHS THEN
            IF dev.Class[dev.classId].GetHSConfigDescriptor # NIL THEN
              dev.ConfDesc := dev.Class[dev.classId].GetHSConfigDescriptor()
            END
          ELSE (* use USB FS *)
            IF dev.Class[dev.classId].GetFSConfigDescriptor # NIL THEN
              dev.ConfDesc := dev.Class[dev.classId].GetFSConfigDescriptor()
            END
          END;
          INC(dev.NumClasses) (* Increment the NumClasses *)
        END;
        Log.Flush
    | Def.Handle: ASSERT(FALSE)
    END
  END RegisterClass;

END USBD.
