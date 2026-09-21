import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { UserService } from '../user/user.service';
import { User, UserRole } from '../user/user.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    fullName: string;
    phone?: string;
    avatarUrl?: string;
    role: UserRole;
  };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly userService: UserService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(registerDto: RegisterDto): Promise<AuthResponse> {
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(registerDto.password, saltRounds);

    const newUser = await this.userService.create({
      email: registerDto.email,
      passwordHash,
      fullName: registerDto.fullName,
      phone: registerDto.phone,
      role: UserRole.CUSTOMER,
    });

    return this.generateAuthResponse(newUser);
  }

  async login(loginDto: LoginDto): Promise<AuthResponse> {
    const user = await this.userService.findByEmail(loginDto.email, true);
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Email hoặc mật khẩu không chính xác');
    }

    const isPasswordValid = await bcrypt.compare(loginDto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Email hoặc mật khẩu không chính xác');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Tài khoản đã bị tạm khóa');
    }

    return this.generateAuthResponse(user);
  }

  async loginWithGoogle(googleDto: GoogleAuthDto): Promise<AuthResponse> {
    let user = await this.userService.findByGoogleId(googleDto.googleId);

    if (!user) {
      user = await this.userService.findByEmail(googleDto.email);
      if (user) {
        user = await this.userService.updateGoogleId(user.id, googleDto.googleId, googleDto.avatarUrl);
      } else {
        user = await this.userService.create({
          email: googleDto.email,
          fullName: googleDto.fullName,
          googleId: googleDto.googleId,
          avatarUrl: googleDto.avatarUrl,
          role: UserRole.CUSTOMER,
        });
      }
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Tài khoản đã bị tạm khóa');
    }

    return this.generateAuthResponse(user);
  }

  private generateAuthResponse(user: User): AuthResponse {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_SECRET') || 'super_secret_key_smart_city_food_route_2026',
      expiresIn: this.configService.get<string>('JWT_EXPIRES_IN') || '7d',
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET') || 'super_refresh_secret_key_2026',
      expiresIn: this.configService.get<string>('JWT_REFRESH_EXPIRES_IN') || '30d',
    });

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        role: user.role,
      },
    };
  }
}
