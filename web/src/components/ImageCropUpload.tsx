import React, { useState, useRef, useEffect } from 'react';
import {
  Upload,
  Crop,
  Check,
  X,
  Image as ImageIcon,
  ZoomIn,
  ZoomOut,
  RotateCcw,
  RotateCw,
  Maximize2,
  RefreshCw,
  Edit3,
  Trash2,
  Grid,
} from 'lucide-react';
import { apiFetch } from '../api/apiClient';
import { getImageUrl } from '../utils/imageUtils';

interface ImageCropUploadProps {
  value?: string;
  initialImage?: string;
  onChange?: (url: string) => void;
  onImageCropped?: (url: string) => void;
  label?: string;
  aspectRatio?: number; // 1: 1:1 square, 1.77: 16:9 banner, 1.58: CCCD
}

export const ImageCropUpload: React.FC<ImageCropUploadProps> = ({
  value,
  initialImage,
  onChange,
  onImageCropped,
  label = 'Hình ảnh',
  aspectRatio = 1,
}) => {
  const currentValue = value || initialImage || '';
  const triggerChange = (url: string) => {
    if (onChange) onChange(url);
    if (onImageCropped) onImageCropped(url);
  };

  const [imageSrc, setImageSrc] = useState<string | null>(null);
  const [originalSrc, setOriginalSrc] = useState<string | null>(null);
  const [isCropping, setIsCropping] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  const [currentAspect, setCurrentAspect] = useState<number>(aspectRatio);
  const [imageError, setImageError] = useState(false);

  const [scale, setScale] = useState(1);
  const [rotation, setRotation] = useState(0); // 0, 90, 180, 270
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });

  const imageRef = useRef<HTMLImageElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const cropFrameRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    setCurrentAspect(aspectRatio);
  }, [aspectRatio]);

  useEffect(() => {
    setImageError(false);
  }, [currentValue]);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      const file = e.target.files[0];
      const reader = new FileReader();
      reader.onload = () => {
        const src = reader.result as string;
        setOriginalSrc(src);
        setImageSrc(src);
        setScale(1);
        setRotation(0);
        setOffset({ x: 0, y: 0 });
        setIsCropping(true);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleOpenEdit = () => {
    const srcToUse = originalSrc || currentValue;
    if (!srcToUse) return;
    setImageSrc(srcToUse);
    setScale(1);
    setRotation(0);
    setOffset({ x: 0, y: 0 });
    setIsCropping(true);
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

  // Touch drag support for mobile/tablets
  const handleTouchStart = (e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      setIsDragging(true);
      setDragStart({
        x: e.touches[0].clientX - offset.x,
        y: e.touches[0].clientY - offset.y,
      });
    }
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!isDragging || e.touches.length !== 1) return;
    setOffset({
      x: e.touches[0].clientX - dragStart.x,
      y: e.touches[0].clientY - dragStart.y,
    });
  };

  // Mouse wheel zoom
  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const delta = e.deltaY < 0 ? 0.05 : -0.05;
    setScale((prev) => Math.max(0.15, Math.min(prev + delta, 4)));
  };

  const handleRotateLeft = () => {
    setRotation((prev) => (prev - 90 + 360) % 360);
  };

  const handleRotateRight = () => {
    setRotation((prev) => (prev + 90) % 360);
  };

  const handleReset = () => {
    setScale(1);
    setRotation(0);
    setOffset({ x: 0, y: 0 });
  };

  const getCropFrameSize = () => {
    const cropFrameW = currentAspect >= 1 ? 240 : Math.round(240 * currentAspect);
    const cropFrameH = Math.round(cropFrameW / currentAspect);
    return { cropFrameW, cropFrameH };
  };

  const handleFitToFrame = () => {
    if (!imageRef.current || !containerRef.current) {
      setScale(0.8);
      setOffset({ x: 0, y: 0 });
      return;
    }
    const img = imageRef.current;
    const naturalW = img.naturalWidth || 600;
    const naturalH = img.naturalHeight || 400;
    const containerW = containerRef.current.clientWidth || 540;
    const containerH = containerRef.current.clientHeight || 320;

    const baseDOMScale = Math.min(containerW / naturalW, containerH / naturalH);
    const domW = naturalW * baseDOMScale;
    const domH = naturalH * baseDOMScale;

    const { cropFrameW, cropFrameH } = getCropFrameSize();

    const isRotated90 = rotation === 90 || rotation === 270;
    const effW = isRotated90 ? domH : domW;
    const effH = isRotated90 ? domW : domH;

    const fitScale = Math.min(cropFrameW / effW, cropFrameH / effH);
    setScale(Math.max(0.15, Math.min(fitScale * 0.98, 4)));
    setOffset({ x: 0, y: 0 });
  };

  const handleFillFrame = () => {
    if (!imageRef.current || !containerRef.current) return;
    const img = imageRef.current;
    const naturalW = img.naturalWidth || 600;
    const naturalH = img.naturalHeight || 400;
    const containerW = containerRef.current.clientWidth || 540;
    const containerH = containerRef.current.clientHeight || 320;

    const baseDOMScale = Math.min(containerW / naturalW, containerH / naturalH);
    const domW = naturalW * baseDOMScale;
    const domH = naturalH * baseDOMScale;

    const { cropFrameW, cropFrameH } = getCropFrameSize();

    const isRotated90 = rotation === 90 || rotation === 270;
    const effW = isRotated90 ? domH : domW;
    const effH = isRotated90 ? domW : domH;

    const fillScale = Math.max(cropFrameW / effW, cropFrameH / effH);
    setScale(Math.max(0.15, Math.min(fillScale, 4)));
    setOffset({ x: 0, y: 0 });
  };

  const handleCropAndUpload = async () => {
    if (!imageRef.current || !containerRef.current) return;
    setUploading(true);

    try {
      const img = imageRef.current;
      const containerEl = containerRef.current;
      const containerW = containerEl.clientWidth || 540;
      const containerH = containerEl.clientHeight || 340;

      const naturalW = img.naturalWidth || 600;
      const naturalH = img.naturalHeight || 400;

      const isRotated90 = rotation === 90 || rotation === 270;
      const tempW = isRotated90 ? naturalH : naturalW;
      const tempH = isRotated90 ? naturalW : naturalH;

      // 1. Create temporary canvas with the image rotated to current angle
      const tempCanvas = document.createElement('canvas');
      tempCanvas.width = tempW;
      tempCanvas.height = tempH;

      const tempCtx = tempCanvas.getContext('2d');
      if (tempCtx) {
        tempCtx.fillStyle = '#ffffff';
        tempCtx.fillRect(0, 0, tempW, tempH);
        tempCtx.translate(tempW / 2, tempH / 2);
        tempCtx.rotate((rotation * Math.PI) / 180);
        tempCtx.drawImage(img, -naturalW / 2, -naturalH / 2);
      }

      // 2. Unscaled DOM base scale (how browser scales img into containerW x containerH)
      const domScale = Math.min(containerW / tempW, containerH / tempH);

      // 3. Crop frame size in DOM
      const { cropFrameW, cropFrameH } = getCropFrameSize();

      // 4. Exact crop box in tempCanvas image pixels (derived directly from scale & offset)
      const cropWInImg = cropFrameW / (domScale * scale);
      const cropHInImg = cropFrameH / (domScale * scale);

      const centerXInImg = tempW / 2 - offset.x / (domScale * scale);
      const centerYInImg = tempH / 2 - offset.y / (domScale * scale);

      const sx = centerXInImg - cropWInImg / 2;
      const sy = centerYInImg - cropHInImg / 2;

      // 5. Output canvas
      const targetWidth = 600;
      const targetHeight = Math.round(600 / currentAspect);

      const canvas = document.createElement('canvas');
      canvas.width = targetWidth;
      canvas.height = targetHeight;
      const ctx = canvas.getContext('2d');

      if (ctx) {
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, targetWidth, targetHeight);

        ctx.drawImage(
          tempCanvas,
          sx,
          sy,
          cropWInImg,
          cropHInImg,
          0,
          0,
          targetWidth,
          targetHeight
        );
      }

      const croppedBase64 = canvas.toDataURL('image/jpeg', 0.92);

      const oldUrl = currentValue;
      let finalUrl = '';
      try {
        const res = await apiFetch<{ url: string }>('/upload', {
          method: 'POST',
          body: JSON.stringify({ image: croppedBase64 }),
        });
        finalUrl = res.url || (res as any).data?.url;
        if (!finalUrl) throw new Error('Không nhận được đường dẫn ảnh từ máy chủ');
      } catch (uploadErr: any) {
        setNotice(`❌ Lỗi tải ảnh lên máy chủ: ${uploadErr.message || 'Vui lòng kiểm tra kết nối'}`);
        setTimeout(() => setNotice(null), 6000);
        return;
      }

      // Automatically delete the old file from uploads/ directory if user re-crops or updates image
      if (oldUrl && oldUrl.includes('/uploads/') && oldUrl !== finalUrl) {
        apiFetch('/upload/file', {
          method: 'DELETE',
          body: JSON.stringify({ url: oldUrl }),
        }).catch(() => {});
      }

      setOriginalSrc(imageSrc);
      triggerChange(finalUrl);
      setIsCropping(false);
      setNotice('✅ Đã cắt & cập nhật ảnh preview! Hãy nhấn nút "Lưu Thay Đổi" bên dưới để hoàn tất.');
      setTimeout(() => setNotice(null), 6000);
    } catch (err: any) {
      console.error('Lỗi cắt ảnh:', err);
    } finally {
      setUploading(false);
    }
  };

  const { cropFrameW, cropFrameH } = getCropFrameSize();

  return (
    <div style={{ marginBottom: '16px' }}>
      <label className="form-label">{label}</label>

      <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
        {currentValue && !imageError ? (
          <div
            style={{
              position: 'relative',
              width: aspectRatio > 1 ? '140px' : '80px',
              height: '80px',
              borderRadius: '10px',
              overflow: 'hidden',
              border: '2px solid #fc6011',
              background: '#f8fafc',
            }}
          >
            <img
              key={currentValue}
              src={getImageUrl(currentValue)}
              alt="Preview"
              onError={() => setImageError(true)}
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
          </div>
        ) : (
          <div
            style={{
              width: aspectRatio > 1 ? '140px' : '80px',
              height: '80px',
              borderRadius: '10px',
              border: '2px dashed #cbd5e1',
              background: '#f8fafc',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#94a3b8',
            }}
          >
            <ImageIcon size={28} />
          </div>
        )}

        <div>
          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
            {currentValue && (
              <button
                type="button"
                className="btn btn-outline btn-sm"
                onClick={handleOpenEdit}
                style={{ display: 'flex', alignItems: 'center', gap: '4px' }}
              >
                <Edit3 size={14} color="#fc6011" /> Chỉnh Sửa / Cắt Lại
              </button>
            )}

            <label
              className="btn btn-outline btn-sm"
              style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
            >
              <Upload size={14} /> {currentValue ? 'Tải Ảnh Mới' : 'Upload & Cắt Ảnh'}
              <input type="file" accept="image/*" onChange={handleFileSelect} style={{ display: 'none' }} />
            </label>

            {currentValue && (
              <button
                type="button"
                className="btn btn-outline btn-sm"
                onClick={() => {
                  if (currentValue && currentValue.includes('/uploads/img_')) {
                    apiFetch('/upload/file', {
                      method: 'DELETE',
                      body: JSON.stringify({ url: currentValue }),
                    }).catch(() => {});
                  }
                  triggerChange('');
                }}
                style={{ color: '#ef4444', borderColor: '#fca5a5' }}
                title="Xóa ảnh"
              >
                <Trash2 size={14} /> Xóa
              </button>
            )}
          </div>

          {notice && (
            <div
              style={{
                marginTop: '8px',
                padding: '8px 12px',
                background: '#dcfce7',
                color: '#15803d',
                borderRadius: '6px',
                fontSize: '12px',
                fontWeight: 600,
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                border: '1px solid #86efac',
              }}
            >
              <Check size={14} /> {notice}
            </div>
          )}

          <div style={{ fontSize: '11px', color: '#64748b', marginTop: '6px' }}>
            Hỗ trợ PNG, JPG, WEBP. Kéo di chuyển, cuộn chuột zoom hoặc cắt chuẩn khung.
          </div>
        </div>
      </div>

      {/* Modal Cắt & Xoay Ảnh */}
      {isCropping && imageSrc && (
        <div className="modal-backdrop" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: '620px' }}>
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700 }}>
                <Crop size={18} color="#fc6011" /> Chỉnh Sửa & Cắt Ảnh Chuẩn Vùng Chọn
              </div>
              <button onClick={() => setIsCropping(false)} style={{ color: '#64748b' }}>
                <X size={20} />
              </button>
            </div>

            <div className="modal-body" style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '12px', color: '#475569', marginBottom: '10px', fontWeight: 500 }}>
                💡 <b>Nội dung nằm bên trong viền cam nét đứt sẽ là ảnh đầu ra sau khi cắt.</b>
              </div>

              {/* Aspect ratio options toolbar */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', marginBottom: '12px' }}>
                <span style={{ fontSize: '12px', color: '#64748b', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Grid size={13} /> Tỷ lệ khung:
                </span>
                <button
                  type="button"
                  className={`btn btn-sm ${currentAspect === 1 ? 'btn-primary' : 'btn-outline'}`}
                  onClick={() => setCurrentAspect(1)}
                  style={{ fontSize: '11px', padding: '3px 8px' }}
                >
                  1:1 (Vuông)
                </button>
                <button
                  type="button"
                  className={`btn btn-sm ${Math.abs(currentAspect - 1.333) < 0.05 ? 'btn-primary' : 'btn-outline'}`}
                  onClick={() => setCurrentAspect(4 / 3)}
                  style={{ fontSize: '11px', padding: '3px 8px' }}
                >
                  4:3 (Nằm)
                </button>
                <button
                  type="button"
                  className={`btn btn-sm ${Math.abs(currentAspect - 1.777) < 0.05 ? 'btn-primary' : 'btn-outline'}`}
                  onClick={() => setCurrentAspect(16 / 9)}
                  style={{ fontSize: '11px', padding: '3px 8px' }}
                >
                  16:9 (Rộng)
                </button>
              </div>

              {/* Interactive Cropping Workspace Container */}
              <div
                ref={containerRef}
                onMouseDown={handleMouseDown}
                onMouseMove={handleMouseMove}
                onMouseUp={handleMouseUp}
                onMouseLeave={handleMouseUp}
                onTouchStart={handleTouchStart}
                onTouchMove={handleTouchMove}
                onTouchEnd={handleMouseUp}
                onWheel={handleWheel}
                style={{
                  width: '100%',
                  height: '340px',
                  background: '#0f172a',
                  borderRadius: '12px',
                  position: 'relative',
                  overflow: 'hidden',
                  cursor: isDragging ? 'grabbing' : 'grab',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  userSelect: 'none',
                }}
              >
                <img
                  ref={imageRef}
                  src={imageSrc}
                  alt="Cropping target"
                  style={{
                    position: 'absolute',
                    transform: `translate(${offset.x}px, ${offset.y}px) scale(${scale}) rotate(${rotation}deg)`,
                    maxHeight: '100%',
                    maxWidth: '100%',
                    userSelect: 'none',
                    transition: isDragging ? 'none' : 'transform 0.08s linear',
                  }}
                  draggable={false}
                />

                {/* Precise Overlay Orange Crop Box */}
                <div
                  ref={cropFrameRef}
                  style={{
                    position: 'absolute',
                    width: `${cropFrameW}px`,
                    height: `${cropFrameH}px`,
                    border: '2.5px dashed #fc6011',
                    boxShadow: '0 0 0 9999px rgba(15, 23, 42, 0.78)',
                    pointerEvents: 'none',
                    borderRadius: '8px',
                    transition: 'width 0.2s ease, height 0.2s ease',
                  }}
                />
              </div>

              {/* Quick Action Buttons */}
              <div style={{ display: 'flex', gap: '8px', justifyContent: 'center', marginTop: '12px' }}>
                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  onClick={handleFitToFrame}
                  title="Thu nhỏ để lấy toàn bộ ảnh không bị cắt mép"
                  style={{ fontSize: '12px', borderColor: '#fc6011', color: '#fc6011', fontWeight: 600 }}
                >
                  <Maximize2 size={13} /> Vừa Khung (Không Mất Góc)
                </button>

                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  onClick={handleFillFrame}
                  title="Phóng to để phủ kín hoàn toàn khung cắt"
                  style={{ fontSize: '12px' }}
                >
                  Phủ Kín Khung
                </button>

                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  onClick={handleReset}
                  title="Đặt lại vị trí & góc xoay"
                  style={{ fontSize: '12px' }}
                >
                  <RefreshCw size={13} /> Đặt Lại
                </button>
              </div>

              {/* Controls: Rotate & Zoom Slider */}
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: '12px',
                  marginTop: '14px',
                  padding: '0 8px',
                }}
              >
                <div style={{ display: 'flex', gap: '6px' }}>
                  <button
                    type="button"
                    className="btn btn-outline btn-sm"
                    onClick={handleRotateLeft}
                    title="Xoay Trái 90°"
                    style={{ padding: '6px 10px' }}
                  >
                    <RotateCcw size={14} /> Xoay Trái
                  </button>
                  <button
                    type="button"
                    className="btn btn-outline btn-sm"
                    onClick={handleRotateRight}
                    title="Xoay Phải 90°"
                    style={{ padding: '6px 10px' }}
                  >
                    <RotateCw size={14} /> Xoay Phải
                  </button>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flex: 1, maxWidth: '240px' }}>
                  <ZoomOut size={16} color="#64748b" />
                  <input
                    type="range"
                    min="0.15"
                    max="3.5"
                    step="0.02"
                    value={scale}
                    onChange={(e) => setScale(parseFloat(e.target.value))}
                    style={{ flex: 1, accentColor: '#fc6011' }}
                  />
                  <ZoomIn size={16} color="#64748b" />
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn btn-outline" onClick={() => setIsCropping(false)} disabled={uploading}>
                Hủy Bỏ
              </button>
              <button className="btn btn-primary" onClick={handleCropAndUpload} disabled={uploading}>
                {uploading ? <div className="loading-spinner" /> : <><Check size={16} /> Lưu & Sử Dụng Ảnh</>}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
