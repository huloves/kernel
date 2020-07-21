#ifndef _SRV_GUI_SRV_H
#define _SRV_GUI_SRV_H

/* gui server call */
#if 0
enum guisrv_call_num {
    GUISRV_OPEN_DISPLAY = 0,
    GUISRV_CLOSE_DISPLAY,
    GUISRV_CREATE_WIN,
    GUISRV_DESTROY_WIN,
    GUISRV_MAP_WIN,
    GUISRV_UNMAP_WIN,
    GUISRV_SET_WMNAME,
    GUISRV_SET_WMICONNAME,
    GUISRV_SET_WMICON,
    GUISRV_SELECT_INPUT,
    GUISRV_CALL_NR,    /* 最大数量 */
};
#endif
enum guisrv_call_num {
    GUISRV_CONNECT = 0,
    GUISRV_CLOSE,
    GUISRV_CLEAR,
    GUISRV_CALL_NR,    /* 最大数量 */
};

#endif   /* _SRV_GUI_SRV_H */