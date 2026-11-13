import { Request, Response } from 'express';
import { LegalDocumentService } from '../services/legal_document_service';

export class LegalDocumentController {
  private service = LegalDocumentService.getInstance();

  /**
   * Public/App: Get active documents
   */
  getActiveDocuments = async (req: Request, res: Response) => {
    try {
      const result = await this.service.getActiveDocuments();
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        data: result,
      });
    } catch (error: any) {
      console.error('[LegalDocumentController] Lỗi lấy điều khoản active:', error.message);
      return res.status(500).json({ statusCode: 500, message: error.message || 'Lỗi máy chủ' });
    }
  };

  /**
   * Admin: List documents with pagination & filter
   */
  getAdminDocuments = async (req: Request, res: Response) => {
    try {
      const result = await this.service.getAdminDocuments(req.query as any);
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        data: result,
      });
    } catch (error: any) {
      console.error('[LegalDocumentController] Lỗi danh sách admin:', error.message);
      return res.status(500).json({ statusCode: 500, message: error.message || 'Lỗi máy chủ' });
    }
  };

  /**
   * Admin: Get detail of one document
   */
  getDocumentDetail = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      if (!id || isNaN(id)) {
        return res.status(400).json({ statusCode: 400, message: 'ID tài liệu không hợp lệ' });
      }
      const result = await this.service.getDocumentById(id);
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        data: result,
      });
    } catch (error: any) {
      return res.status(404).json({ statusCode: 404, message: error.message || 'Không tìm thấy tài liệu' });
    }
  };

  /**
   * Admin: Create a draft
   */
  createDraft = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      const result = await this.service.createDraft(
        {
          maTaiKhoan: user.sub || user.maTaiKhoan,
          tenDangNhap: user.tenDangNhap,
          email: user.email,
          role: user.role || user.loaiTaiKhoan,
        },
        req.body
      );
      return res.status(201).json({
        statusCode: 201,
        status: '1',
        message: 'Tạo bản nháp điều khoản thành công',
        data: result,
      });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Lỗi tạo bản nháp' });
    }
  };

  /**
   * Admin: Update draft
   */
  updateDraft = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const user = (req as any).user;
      const result = await this.service.updateDraft(
        id,
        {
          maTaiKhoan: user.sub || user.maTaiKhoan,
          tenDangNhap: user.tenDangNhap,
          email: user.email,
          role: user.role || user.loaiTaiKhoan,
        },
        req.body
      );
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Cập nhật tài liệu thành công',
        data: result,
      });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Lỗi cập nhật tài liệu' });
    }
  };

  /**
   * Admin: Delete document
   */
  deleteDraft = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const user = (req as any).user;
      const result = await this.service.deleteDraft(id, {
        maTaiKhoan: user.sub || user.maTaiKhoan,
        tenDangNhap: user.tenDangNhap,
        email: user.email,
        role: user.role || user.loaiTaiKhoan,
      });
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: result.message,
      });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Lỗi xóa tài liệu' });
    }
  };

  /**
   * Admin: Publish draft in transaction
   */
  publishDocument = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const user = (req as any).user;
      const result = await this.service.publishDocument(id, {
        maTaiKhoan: user.sub || user.maTaiKhoan,
        tenDangNhap: user.tenDangNhap,
        email: user.email,
        role: user.role || user.loaiTaiKhoan,
      });
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: `Đã xuất bản thành công phiên bản ${result.soPhienBan}`,
        data: result,
      });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Lỗi xuất bản tài liệu' });
    }
  };
}

