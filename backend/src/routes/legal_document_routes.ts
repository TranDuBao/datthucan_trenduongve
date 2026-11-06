import { Router } from 'express';
import { LegalDocumentController } from '../controllers/legal_document_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { requireRole } from '../middlewares/role_middleware';

const router = Router();
const controller = new LegalDocumentController();

// Public / Mobile Client endpoints
router.get('/legal-documents/active', controller.getActiveDocuments);

// Admin endpoints (strictly guarded by ADMIN role)
router.get('/admin/legal-documents', authMiddleware as any, requireRole(['ADMIN']) as any, controller.getAdminDocuments);
router.get('/admin/legal-documents/:id', authMiddleware as any, requireRole(['ADMIN']) as any, controller.getDocumentDetail);
router.post('/admin/legal-documents', authMiddleware as any, requireRole(['ADMIN']) as any, controller.createDraft);
router.put('/admin/legal-documents/:id', authMiddleware as any, requireRole(['ADMIN']) as any, controller.updateDraft);
router.delete('/admin/legal-documents/:id', authMiddleware as any, requireRole(['ADMIN']) as any, controller.deleteDraft);
router.post('/admin/legal-documents/:id/publish', authMiddleware as any, requireRole(['ADMIN']) as any, controller.publishDocument);

export default router;

