import React, { useState, useRef, useEffect } from 'react';
import { Upload, Crop, Check, X, Image as ImageIcon, ZoomIn, ZoomOut } from 'lucide-react';
import { apiFetch } from '../api/apiClient';

interface ImageCropUploadProps {
  value?: string;
  onChange: (url: string) => void;
  label?: string;
  aspectRatio?: number; // 1: 1:1 square, 1.77: 16:9 banner
}

export const ImageCropUpload: React.FC<ImageCropUploadProps> = ({
  value,
  onChange,
  label = 'Hình ảnh',
  aspectRatio = 1,
}) => {
  const [imageSrc, setImageSrc] = useState<string | null>(null);
  const [isCropping, setIsCropping] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [scale, setScale] = useState(1);
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });

  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const imageRef = useRef<HTMLImageElement | null>(null);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      const file = e.target.files[0];
      const reader = new FileReader();
      reader.onload = () => {
        setImageSrc(reader.result as string);
        setScale(1);
        setOffset({ x: 0, y: 0 });
        setIsCropping(true);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleMouseDown = (e: React.MouseEvent) => {
    setIsDragging(true);
    setDragStart({ x: e.clientX - offset.x, y: e.clientY - offset.y });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging) return;
    setOffset({
      x: e.clientX - dragStart.x,
      y: e.clientY - dragStart.y,
    });
  };

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  const handleCropAndUpload = async () => {
    if (!imageSrc) return;
    setUploading(true);

    try {
      const img = new Image();
      img.src = imageSrc;
      await new Promise((resolve) => (img.onload = resolve));

      const canvas = document.createElement('canvas');
      const targetWidth = aspectRatio === 1 ? 500 : 800;
      const targetHeight = Math.round(targetWidth / aspectRatio);

      canvas.width = targetWidth;
      canvas.height = targetHeight;
      const ctx = canvas.getContext('2d');

      if (ctx) {
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, targetWidth, targetHeight);

        // Center transformation math
        const drawWidth = targetWidth * scale;
        const drawHeight = (targetWidth / (img.width / img.height)) * scale;

        const drawX = (targetWidth - drawWidth) / 2 + offset.x;
        const drawY = (targetHeight - drawHeight) / 2 + offset.y;

        ctx.drawImage(img, drawX, drawY, drawWidth, drawHeight);
      }

      const croppedBase64 = canvas.toDataURL('image/jpeg', 0.85);

      try {
        // Try uploading to backend server endpoint
        const res = await apiFetch<{ url: string }>('/upload', {
          method: 'POST',
          body: JSON.stringify({ image: croppedBase64 }),
        });
        const uploadedUrl = res.url || (res as any).data?.url || croppedBase64;
        onChange(uploadedUrl);
      } catch (uploadErr) {
        console.warn('⚠️ Server /upload chưa khởi động lại, tự động sử dụng ảnh đã cắt dạng base64:', uploadErr);
        // Fallback to cropped Base64 image
        onChange(croppedBase64);
      }

      setIsCropping(false);
    } catch (err: any) {
      alert(err.message || 'Lỗi cắt hình ảnh');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div style={{ marginBottom: '16px' }}>
      <label className="form-label">{label}</label>

      <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
        {value ? (
          <div style={{ position: 'relative', width: aspectRatio > 1 ? '140px' : '80px', height: '80px', borderRadius: '10px', overflow: 'hidden', border: '1px solid #e2e8f0', background: '#f8fafc' }}>
            <img src={value} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          </div>
        ) : (
          <div style={{ width: aspectRatio > 1 ? '140px' : '80px', height: '80px', borderRadius: '10px', border: '2px dashed #cbd5e1', background: '#f8fafc', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#94a3b8' }}>
            <ImageIcon size={28} />
          </div>
        )}

        <div>
          <label className="btn btn-outline btn-sm" style={{ cursor: 'pointer' }}>
            <Upload size={14} /> Upload & Cắt Ảnh
            <input type="file" accept="image/*" onChange={handleFileSelect} style={{ display: 'none' }} />
          </label>
          <div style={{ fontSize: '11px', color: '#64748b', marginTop: '6px' }}>
            Hỗ trợ PNG, JPG, WEBP. Cho phép chỉnh sửa & cắt khung hình.
          </div>
        </div>
      </div>

      {/* Modal Cắt Ảnh (Cropper Modal) */}
      {isCropping && imageSrc && (
        <div className="modal-backdrop" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: '560px' }}>
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700 }}>
                <Crop size={18} color="#fc6011" /> Cắt & Chỉnh Sửa Khung Ảnh
              </div>
              <button onClick={() => setIsCropping(false)} style={{ color: '#64748b' }}>
                <X size={20} />
              </button>
            </div>

            <div className="modal-body" style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '12px', color: '#64748b', marginBottom: '12px' }}>
                Kéo ảnh để di chuyển vị trí • Dùng thanh trượt để phóng to / thu nhỏ
              </div>

              {/* Khung cắt ảnh interactive */}
              <div
                onMouseDown={handleMouseDown}
                onMouseMove={handleMouseMove}
                onMouseUp={handleMouseUp}
                onMouseLeave={handleMouseUp}
                style={{
                  width: '100%',
                  height: '280px',
                  background: '#0f172a',
                  borderRadius: '12px',
                  position: 'relative',
                  overflow: 'hidden',
                  cursor: isDragging ? 'grabbing' : 'grab',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <img
                  ref={imageRef}
                  src={imageSrc}
                  alt="Cropping target"
                  style={{
                    position: 'absolute',
                    transform: `translate(${offset.x}px, ${offset.y}px) scale(${scale})`,
                    maxHeight: '100%',
                    maxWidth: '100%',
                    userSelect: 'none',
                    transition: isDragging ? 'none' : 'transform 0.1s ease',
                  }}
                  draggable={false}
                />

                {/* Khung căn lề Crop Overlay Box */}
                <div
                  style={{
                    position: 'absolute',
                    width: aspectRatio === 1 ? '200px' : '320px',
                    height: '200px',
                    border: '2px solid #fc6011',
                    boxShadow: '0 0 0 9999px rgba(15, 23, 42, 0.75)',
                    pointerEvents: 'none',
                    borderRadius: '8px',
                  }}
                />
              </div>

              {/* Zoom Control Slider */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginTop: '16px', padding: '0 12px' }}>
                <ZoomOut size={16} color="#64748b" />
                <input
                  type="range"
                  min="0.5"
                  max="3"
                  step="0.05"
                  value={scale}
                  onChange={(e) => setScale(parseFloat(e.target.value))}
                  style={{ flex: 1, accentColor: '#fc6011' }}
                />
                <ZoomIn size={16} color="#64748b" />
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn btn-outline" onClick={() => setIsCropping(false)} disabled={uploading}>
                Hủy Bỏ
              </button>
              <button className="btn btn-primary" onClick={handleCropAndUpload} disabled={uploading}>
                {uploading ? <div className="loading-spinner" /> : <><Check size={16} /> Cắt & Sử Dụng Ảnh</>}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
