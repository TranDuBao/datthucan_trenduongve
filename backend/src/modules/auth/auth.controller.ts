import { Controller, Post, Body, Get, UseGuards, Request, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Controller('api/v1/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() registerDto: RegisterDto) {
    const result = await this.authService.register(registerDto);
    return {
      statusCode: HttpStatus.CREATED,
      message: 'Đăng ký tài khoản thành công',
      data: result,
    };
  }

  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    const result = await this.authService.login(loginDto);
    return {
      statusCode: HttpStatus.OK,
      message: 'Đăng nhập thành công',
      data: result,
    };
  }

  @HttpCode(HttpStatus.OK)
  @Post('google')
  async googleAuth(@Body() googleDto: GoogleAuthDto) {
    const result = await this.authService.loginWithGoogle(googleDto);
    return {
      statusCode: HttpStatus.OK,
      message: 'Đăng nhập Google thành công',
      data: result,
    };
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getProfile(@Request() req: any) {
    return {
      statusCode: HttpStatus.OK,
      message: 'Lấy thông tin cá nhân thành công',
      data: req.user,
    };
  }
}
