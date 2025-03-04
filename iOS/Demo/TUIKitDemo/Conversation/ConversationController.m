//
//  ConversationViewController.m
//  TUIKitDemo
//
//  Created by kennethmiao on 2018/10/10.
//  Copyright © 2018年 Tencent. All rights reserved.
//
#import "ConversationController.h"
#import "TUIConversationListController.h"
#import "TUIC2CChatViewController.h"
#import "TUIGroupChatViewController.h"
#import "TUIContactSelectController.h"
#import "TUIThemeManager.h"
#import "TPopView.h"
#import "TPopCell.h"
#import "TUIDefine.h"
#import "TUITool.h"
#import "TUIKit.h"
#import "TCUtil.h"
#import "TUIGroupService.h"
#import "TUIFoldListViewController.h"
#import "TUIGroupCreateController.h"

@interface ConversationController () <TUIConversationListControllerListener, TPopViewDelegate, V2TIMSDKListener>
@property (nonatomic, strong) TUINaviBarIndicatorView *titleView;
@end

@implementation ConversationController

- (void)viewDidLoad {
    [super viewDidLoad];

    TUIConversationListController *conv = [[TUIConversationListController alloc] init];
    conv.delegate = self;
    [self addChildViewController:conv];
    [self.view addSubview:conv.view];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [moreButton setImage:TUIDemoDynamicImage(@"nav_more_img", [UIImage imageNamed:TUIDemoImagePath(@"more")]) forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(rightBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    moreButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [moreButton.widthAnchor constraintEqualToConstant:24].active = YES;
    [moreButton.heightAnchor constraintEqualToConstant:24].active = YES;
    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithCustomView:moreButton];
    self.navigationItem.rightBarButtonItem = moreItem;
    
    [self setupNavigation];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onFriendInfoChanged:) name:@"FriendInfoChangedNotification" object:nil];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)onFriendInfoChanged:(NSNotification *)notice
{
    V2TIMFriendInfo *friendInfo = notice.object;
    if (friendInfo == nil) {
        return;
    }
    for (UIViewController *vc in self.childViewControllers) {
        if ([vc isKindOfClass:TUIConversationListController.class]) {
            // 此处需要优化，目前修改备注通知均是demo层发出来的，所以.....
            TUIConversationListDataProvider *dataProvider = [(TUIConversationListController *)vc provider];
            for (TUIConversationCellData *cellData in dataProvider.conversationList) {
                if ([cellData.userID isEqualToString:friendInfo.userID]) {
                    NSString *title = friendInfo.friendRemark;
                    if (title.length == 0) {
                        title = friendInfo.userFullInfo.nickName;
                    }
                    if (title.length == 0) {
                        title = friendInfo.userID;
                    }
                    cellData.title = title;
                    [[(TUIConversationListController *)vc tableView] reloadData];
                    break;
                }
            }
            break;
        }
    }
}


- (void)setupNavigation
{
    _titleView = [[TUINaviBarIndicatorView alloc] init];
    [_titleView setTitle:NSLocalizedString(@"AppMainTitle", nil)];
    self.navigationItem.titleView = _titleView;
    self.navigationItem.title = @"";
    [[V2TIMManager sharedInstance] addIMSDKListener:self];
}


- (void)onNetworkChanged:(TUINetStatus)status
{
    [TUITool dispatchMainAsync:^{
        switch (status) {
            case TNet_Status_Succ:
                [self.titleView setTitle:NSLocalizedString(@"AppMainTitle", nil)];
                [self.titleView stopAnimating];
                break;
            case TNet_Status_Connecting:
                [self.titleView setTitle:NSLocalizedString(@"AppMainConnectingTitle", nil)];
                [self.titleView startAnimating];
                break;
            case TNet_Status_Disconnect:
                [self.titleView setTitle:NSLocalizedString(@"AppMainDisconnectTitle", nil)];
                [self.titleView stopAnimating];
                break;
            case TNet_Status_ConnFailed:
                [self.titleView setTitle:NSLocalizedString(@"AppMainDisconnectTitle", nil)];
                [self.titleView stopAnimating];
                break;
                
            default:
                break;
        }
    }];
}

- (void)pushToChatViewController:(NSString *)groupID userID:(NSString *)userID {

    UIViewController *topVc = self.navigationController.topViewController;
    BOOL isSameTarget = NO;
    BOOL isInChat = NO;
    if ([topVc isKindOfClass:TUIC2CChatViewController.class] || [topVc isKindOfClass:TUIGroupChatViewController.class]) {
        TUIChatConversationModel *cellData = [(TUIBaseChatViewController *)topVc conversationData];
        isSameTarget = [cellData.groupID isEqualToString:groupID] || [cellData.userID isEqualToString:userID];
        isInChat = YES;
    }
    if (isInChat && isSameTarget) {
        return;
    }
    
    if (isInChat && !isSameTarget) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    
    TUIChatConversationModel *conversationData = [[TUIChatConversationModel alloc] init];
    conversationData.userID = userID;
    conversationData.groupID = groupID;
    TUIBaseChatViewController *chatVC = [self getChatViewController:conversationData];
    [self.navigationController pushViewController:chatVC animated:YES];
}

- (void)rightBarButtonClick:(UIButton *)rightBarButton
{
    NSMutableArray *menus = [NSMutableArray array];
    TPopCellData *friend = [[TPopCellData alloc] init];
    
    friend.image = TUIDemoDynamicImage(@"pop_icon_new_chat_img", [UIImage imageNamed:TUIDemoImagePath(@"new_chat")]);
    friend.title = NSLocalizedString(@"ChatsNewChatText", nil);
    [menus addObject:friend];
    
    TPopCellData *group = [[TPopCellData alloc] init];
    group.image = TUIDemoDynamicImage(@"pop_icon_new_group_img", [UIImage imageNamed:TUIDemoImagePath(@"new_groupchat")]);
    group.title = NSLocalizedString(@"ChatsNewGroupText", nil);
    [menus addObject:group];

    CGFloat height = [TPopCell getHeight] * menus.count + TPopView_Arrow_Size.height;
    CGFloat orginY = StatusBar_Height + NavBar_Height;
    TPopView *popView = [[TPopView alloc] initWithFrame:CGRectMake(Screen_Width - 155, orginY, 145, height)];
    CGRect frameInNaviView = [self.navigationController.view convertRect:rightBarButton.frame fromView:rightBarButton.superview];
    popView.arrowPoint = CGPointMake(frameInNaviView.origin.x + frameInNaviView.size.width * 0.5, orginY);
    popView.delegate = self;
    [popView setData:menus];
    [popView showInWindow:self.view.window];
}

- (void)popView:(TPopView *)popView didSelectRowAtIndex:(NSInteger)index
{
    @weakify(self)
    if(index == 0){
        // launch conversation
        TUIContactSelectController *vc = [TUIContactSelectController new];
        vc.title = NSLocalizedString(@"ChatsSelectContact", nil);
        vc.maxSelectCount = 1;
        [self.navigationController pushViewController:vc animated:YES];
        vc.finishBlock = ^(NSArray<TUICommonContactSelectCellData *> *array) {
            @strongify(self)
            TUIChatConversationModel *data = [[TUIChatConversationModel alloc] init];
            data.userID = array.firstObject.identifier;
            data.title = array.firstObject.title;
            TUIC2CChatViewController *chat = [[TUIC2CChatViewController alloc] init];
            chat.conversationData = data;
            [self.navigationController pushViewController:chat animated:YES];

            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
            [tempArray removeObjectAtIndex:tempArray.count-2];
            self.navigationController.viewControllers = tempArray;
        };
        return;
    }
    else {
        // create discuss group
        TUIContactSelectController *vc = [TUIContactSelectController new];
        vc.title = NSLocalizedString(@"ChatsSelectContact", nil);
        [self.navigationController pushViewController:vc animated:YES];
        vc.finishBlock = ^(NSArray<TUICommonContactSelectCellData *> *array) {
            @strongify(self)

            TUIGroupCreateController * groupCreateController = [[TUIGroupCreateController alloc] init];
            groupCreateController.title = @"";
            [[TUIGroupService shareInstance] getGroupNameNormalFormatByContacts:array completion:^(BOOL success, NSString * _Nonnull groupName) {
                V2TIMGroupInfo * createGroupInfo = [[V2TIMGroupInfo alloc] init];
                createGroupInfo.groupID = @"";
                createGroupInfo.groupName = groupName;
                createGroupInfo.groupType = @"Work";
                groupCreateController.createGroupInfo = createGroupInfo;
                groupCreateController.createContactArray = [NSArray arrayWithArray:array];
                [self.navigationController pushViewController:groupCreateController animated:YES];

            }];
            
            groupCreateController.submitCallback = ^(BOOL isSuccess, V2TIMGroupInfo * _Nonnull info) {
                [self jumpToNewChatVCWhenCreatGroupSuccess:isSuccess info:info];
            };
            return;
        };
        return;
    }

}

- (void)jumpToNewChatVCWhenCreatGroupSuccess:(BOOL)isSuccess info:(V2TIMGroupInfo *)info {
    if (!isSuccess) {
        return;
    }
    TUIChatConversationModel *conversationData = [[TUIChatConversationModel alloc] init];
    conversationData.groupID = info.groupID;
    conversationData.title = info.groupName;
    conversationData.groupType = info.groupType;
    
    TUIGroupChatViewController *vc = [[TUIGroupChatViewController alloc] init];
    vc.conversationData = conversationData;
    
    [self.navigationController pushViewController:vc animated:YES];
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    for (UIViewController * vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:NSClassFromString(@"TUIGroupCreateController")] ||
            [vc isKindOfClass:NSClassFromString(@"TUIContactSelectController")]) {
            [tempArray removeObject:vc];
        }
    }
    
    self.navigationController.viewControllers = tempArray;
}
- (void)addGroup:(NSString *)groupType
       addOption:(V2TIMGroupAddOpt)addOption
    withContacts:(NSArray<TUICommonContactSelectCellData *> *)contacts {
    [[TUIGroupService shareInstance] createGroup:groupType
                                    createOption:addOption
                                        contacts:contacts
                                      completion:^(BOOL success, NSString * _Nonnull groupID, NSString * _Nonnull groupName) {
        if (!success) {
            [TUITool makeToast:NSLocalizedString(@"ChatsCreateFailed", nil)];
            return;
        }
        TUIChatConversationModel *conversationData = [[TUIChatConversationModel alloc] init];
        conversationData.groupID = groupID;
        conversationData.title = groupName;
        conversationData.groupType = groupType;
        
        TUIGroupChatViewController *vc = [[TUIGroupChatViewController alloc] init];
        vc.conversationData = conversationData;
        
        [self.navigationController pushViewController:vc animated:YES];
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
        [tempArray removeObjectAtIndex:tempArray.count-2];
        self.navigationController.viewControllers = tempArray;
    }];
}

#pragma mark TUIConversationListControllerListener

- (NSString *)getConversationDisplayString:(V2TIMConversation *)conversation {
    V2TIMMessage *msg = conversation.lastMessage;
    if (msg.customElem == nil || msg.customElem.data == nil) {
        return nil;
    }
    NSDictionary *param = [TCUtil jsonData2Dictionary:msg.customElem.data];
    if (param != nil && [param isKindOfClass:[NSDictionary class]]) {
        NSString *businessID = param[@"businessID"];
        if (![businessID isKindOfClass:[NSString class]]) {
            return nil;
        }

        // whether custom jump message
        if ([businessID isEqualToString:BussinessID_TextLink] || ([(NSString *)param[@"text"] length] > 0 && [(NSString *)param[@"link"] length] > 0)) {
            NSString *desc = param[@"text"];
            if (msg.status == V2TIM_MSG_STATUS_LOCAL_REVOKED) {
                if(msg.isSelf){
                    desc = NSLocalizedString(@"MessageTipsYouRecallMessage", nil);
                } else if (msg.userID.length > 0){
                    desc = NSLocalizedString(@"MessageTipsOthersRecallMessage", nil);
                } else if (msg.groupID.length > 0) {
                    /**
                     * 对于群组消息的名称显示，优先显示群名片，昵称优先级其次，用户ID优先级最低。
                     * For the name display of group messages, the group business card is displayed first, the nickname has the second priority, and the user ID has the lowest priority.
                     */
                    NSString *userName = msg.nameCard;
                    if (userName.length == 0) {
                        userName = msg.nickName?:msg.sender;
                    }
                    desc = [NSString stringWithFormat:NSLocalizedString(@"MessageTipsOthersRecallMessageFormat", nil), userName];
                }
            }
            return desc;
        }

        // whether the tips message of creating group
        else if ([businessID isEqualToString:BussinessID_GroupCreate] || [param.allKeys containsObject:BussinessID_GroupCreate]) {
            return [NSString stringWithFormat:@"\"%@\"%@",param[@"opUser"],param[@"content"]];
        }
    }
    return nil;
}

- (void)conversationListController:(TUIConversationListController *)conversationController didSelectConversation:(TUIConversationCellData *)conversation
{
    if (conversation.isLocalConversationFoldList) {

        [TUIConversationListDataProvider cacheConversationFoldListSettings_FoldItemIsUnread:NO];
        
        TUIFoldListViewController *foldVC = [[TUIFoldListViewController alloc] init];
        [self.navigationController pushViewController:foldVC animated:YES];

        foldVC.dismissCallback = ^(NSMutableAttributedString * _Nonnull foldStr, NSArray * _Nonnull sortArr , NSArray * _Nonnull needRemoveFromCacheMapArray) {
            conversation.foldSubTitle  = foldStr;
            conversation.subTitle = conversation.foldSubTitle;
            conversation.isMarkAsUnread = NO;
        
            if (sortArr.count <= 0 ) {
                conversation.orderKey = 0;
                if ([conversationController.provider.conversationList  containsObject:conversation]) {
                    [conversationController.provider hideConversation:conversation];
                }
            }
            
            for (NSString * removeId in needRemoveFromCacheMapArray) {
                if ([conversationController.provider.markFoldMap objectForKey:removeId] ) {
                    [conversationController.provider.markFoldMap removeObjectForKey:removeId];
                }
            }
            
            [TUIConversationListDataProvider cacheConversationFoldListSettings_FoldItemIsUnread:NO];
            [[(TUIConversationListController *)conversationController tableView] reloadData];
        };
        return;
    }
    TUIBaseChatViewController *chatVc = [self getChatViewController:[self getConversationModel:conversation]];
    [self.navigationController pushViewController:chatVc animated:YES];
}


- (void)searchController:(UIViewController *)searchVC
                withKey:(NSString *)searchKey
           didSelectType:(TUISearchType)searchType
                    item:(NSObject *)searchItem
    conversationCellData:(TUIConversationCellData *)conversationCellData
{
    if (searchType == TUISearchTypeChatHistory && [searchItem isKindOfClass:V2TIMMessage.class]) {
        /**
         * 点击搜索到的聊天消息
         * Respond to clicked searched chat messages
         */
        TUIBaseChatViewController *chatVc = [self getChatViewController:[self getConversationModel:conversationCellData]];
        chatVc.title = conversationCellData.title;
        chatVc.highlightKeyword = searchKey;
        chatVc.locateMessage = (V2TIMMessage *)searchItem;
        [searchVC.navigationController pushViewController:chatVc animated:YES];
    } else {
        /**
         * 点击搜索到的群组和联系人
         * Respond to clicks on searched groups and contacts
         */
        TUIBaseChatViewController *chatVc = [self getChatViewController:[self getConversationModel:conversationCellData]];
        chatVc.title = conversationCellData.title;
        [searchVC.navigationController pushViewController:chatVc animated:YES];
    }
}

- (TUIChatConversationModel *)getConversationModel:(TUIConversationCellData *)data {
    TUIChatConversationModel *model = [[TUIChatConversationModel alloc] init];
    model.conversationID = data.conversationID;
    model.userID = data.userID;
    model.groupType = data.groupType;
    model.groupID = data.groupID;
    model.userID = data.userID;
    model.title = data.title;
    model.faceUrl = data.faceUrl;
    model.avatarImage = data.avatarImage;
    model.draftText = data.draftText;
    model.atMsgSeqs = data.atMsgSeqs;
    return model;
}

#pragma mark - V2TIMSDKListener
- (void)onConnecting {
    [self onNetworkChanged:TNet_Status_Connecting];
}

- (void)onConnectSuccess {
    [self onNetworkChanged:TNet_Status_Succ];
}

- (void)onConnectFailed:(int)code err:(NSString*)err {
    [self onNetworkChanged:TNet_Status_ConnFailed];
}

- (TUIBaseChatViewController *)getChatViewController:(TUIChatConversationModel *)model {
    TUIBaseChatViewController *chat = nil;
    if (model.userID.length > 0) {
        chat = [[TUIC2CChatViewController alloc] init];
    } else if (model.groupID.length > 0) {
        chat = [[TUIGroupChatViewController alloc] init];
    }
    chat.conversationData = model;
    return chat;
}
@end
