#ifndef IP_UPDATES_HISTORY_DLG_H__
#define IP_UPDATES_HISTORY_DLG_H__

#include "resource.h"

// TODO: sorting by the columns

class CIpUpdatesHistoryDlg : public CDialogImpl<CIpUpdatesHistoryDlg>
{
	IpUpdate *m_ipUpdates; // a reference, doesn't own this

public:
	enum { IDD = IDD_DIALOG_IP_UPDATES_HISTORY};

	BEGIN_MSG_MAP(CSelectNetworkDlg)
		MSG_WM_INITDIALOG(OnInitDialog)
		COMMAND_ID_HANDLER(IDOK, OnButtonOk)
		COMMAND_ID_HANDLER(IDCANCEL, OnButtonOk) // to make 'close window' button work
		COMMAND_ID_HANDLER(IDC_BUTTON_COPY_TO_CLIPBOARD, OnButtonCopyToClipboard)
	END_MSG_MAP()

	CIpUpdatesHistoryDlg(IpUpdate *ipUpdates)
	{
		m_ipUpdates = ipUpdates;
	}

	BOOL OnInitDialog(CWindow /* wndFocus */, LPARAM /* lInitParam */)
	{
		CListViewCtrl m_ipUpdatesList;
		m_ipUpdatesList = GetDlgItem(IDC_LIST_IP_UPDATES_HISTORY);
		// unfortunately LVS_EX_AUTOSIZECOLUMNS is Vista+ only
		//m_ipUpdatesList.SetExtendedListViewStyle(LVS_EX_AUTOSIZECOLUMNS);
		m_ipUpdatesList.AddColumn(_T("Date"), 0);
		m_ipUpdatesList.AddColumn(_T("IP Address"), 1);
		// TOTAL_WIDTH was determined empirically on XP. Not sure if it will be
		// the same on Vista/7 or on systems with a different fonts/dpis
		static const int TOTAL_WIDTH = 246;
		static const int DATE_COLUMN_WIDTH = 150;
		m_ipUpdatesList.SetColumnWidth(0, DATE_COLUMN_WIDTH);
		m_ipUpdatesList.SetColumnWidth(1, TOTAL_WIDTH - DATE_COLUMN_WIDTH);
		IpUpdate *curr = m_ipUpdates;
		int i = 0;
		while (curr && (i < IP_UPDATES_HISTORY_MAX)) {
			TCHAR *ipAddr = StrToTStr(curr->ipAddress);
			TCHAR *time = StrToTStr(curr->time);
			if (time && ipAddr) {
				m_ipUpdatesList.AddItem(i, 0, time);
				if (curr->ok) {
					m_ipUpdatesList.AddItem(i, 1, ipAddr);
				} else {
					TCHAR *s = TStrCat(_T("!"), ipAddr);
					if (s) {
						m_ipUpdatesList.AddItem(i, 1, s);
						free(s);
					}
				}
			}
			free(ipAddr);
			free(time);
			curr = curr->next;
			i++;
		}
		return FALSE;
	}

	LRESULT OnButtonOk(WORD /*wNotifyCode*/, WORD wID, HWND /*hWndCtl*/, BOOL& /*bHandled*/)
	{
		EndDialog(wID);
		return 0;
	};

	LRESULT OnButtonCopyToClipboard(WORD /*wNotifyCode*/, WORD /*wID*/, HWND /*hWndCtl*/, BOOL& /*bHandled*/)
	{
		size_t		sLen;
		char *		s = NULL;
		WCHAR *		unicode = NULL;
		void *		tmp;
		HGLOBAL		handle = NULL;

		if (!OpenClipboard())
			return 0;

		s = IpUpdatesAsText(m_ipUpdates, &sLen);
		if (!s)
			goto Exit;

		::EmptyClipboard();
		handle = GlobalAlloc(GMEM_DDESHARE | GMEM_MOVEABLE, sLen);
		if (!handle)
			goto Exit;
		tmp = GlobalLock(handle);
		memcpy(tmp, s, sLen);
		GlobalUnlock(handle);
		::SetClipboardData(CF_TEXT, handle);
		// clipboard takes ownership of the handle => no need to GlobalFree() it

#if 0
		unicode = StrToWstrSimple(s);
		if (!unicode)
			goto Exit;
		size_t cbUnicodeSize = (wcslen(unicode)) * sizeof(WCHAR);
		handle = GlobalAlloc(GMEM_DDESHARE | GMEM_MOVEABLE, cbUnicodeSize);
		if (!handle)
			goto Exit;
		tmp = GlobalLock(handle);
		memcpy(tmp, unicode, cbUnicodeSize);
		GlobalUnlock(handle);
		::SetClipboardData(CF_UNICODETEXT, handle);
		// clipboard takes ownership of the handle => no need to GlobalFree() it
#endif

Exit:
		::CloseClipboard();
		free(s);
		free(unicode);
		return 0;
	};

};

#endif

