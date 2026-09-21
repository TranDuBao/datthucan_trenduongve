import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum UserRole {
  CUSTOMER = 'customer',
  VENDOR = 'vendor',
  ADMIN = 'admin',
}

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, length: 255 })
  email: string;

  @Column({ name: 'password_hash', nullable: true, select: false })
  passwordHash?: string;

  @Column({ name: 'full_name', length: 255 })
  fullName: string;

  @Column({ nullable: true, length: 20 })
  phone?: string;

  @Column({ name: 'avatar_url', nullable: true, type: 'text' })
  avatarUrl?: string;

  @Column({ name: 'google_id', nullable: true, unique: true, length: 255 })
  googleId?: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.CUSTOMER,
  })
  role: UserRole;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
