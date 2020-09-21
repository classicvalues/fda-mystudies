import {Injectable} from '@angular/core';
import {Profile, UpdateProfile} from './profile.model';
import {ChangePassword} from './profile.model';
import {EntityService} from '../../../service/entity.service';
import {HttpClient} from '@angular/common/http';
import {Observable} from 'rxjs';
import {ApiResponse} from 'src/app/entity/api.response.model';
import {environment} from '@environment';
import {AuthService} from '../../../service/auth.service';
@Injectable({
  providedIn: 'root',
})
export class AccountService {
  constructor(
    private readonly entityService: EntityService<Profile>,
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  fetchUserProfile(): Observable<Profile> {
    return this.entityService.get(
      `/users/${encodeURIComponent(this.authService.getAuthUserId())}`,
    );
  }

  changePassword(changePassword: ChangePassword): Observable<ApiResponse> {
    return this.http.put<ApiResponse>(
      `${environment.authServerUrl}/users/${encodeURIComponent(
        this.authService.getAuthUserId(),
      )}/change_password`,
      changePassword,
    );
  }
  updateUserProfile(
    profileToBeUpdated: UpdateProfile,
  ): Observable<ApiResponse> {
    this.authUserId = this.authService.getAuthUserId();
    return this.http.put<ApiResponse>(
      `${environment.baseUrl}/users/${encodeURIComponent(
        this.authUserId,
      )}/profile`,
      profileToBeUpdated,
    );
  }

  logout(): Observable<ApiResponse> {
    return this.http.post<ApiResponse>(
      `${environment.authServerUrl}/users/${encodeURIComponent(
        this.authUserId,
      )}/logout`,
      '',
    );
  }
}
